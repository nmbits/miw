#include <ruby.h>
#include <ruby/st.h>
#include <xcb/xcb.h>
#include <xcb/xproto.h>
#include <xcb/xkb.h>
#include <cairo/cairo.h>
#include <cairo/cairo-xcb.h>
#include <xkbcommon/xkbcommon-x11.h>

#define MIW_XCB_PIXMAP_GRID 128
#ifndef IconicState
# define IconicState 3
#endif

#define MIW_XCB_XKB_EVENT_TYPE					\
	(XCB_XKB_EVENT_TYPE_NEW_KEYBOARD_NOTIFY |	\
	 XCB_XKB_EVENT_TYPE_MAP_NOTIFY          |	\
	 XCB_XKB_EVENT_TYPE_STATE_NOTIFY)

typedef struct miw_xcb_window_
{
	xcb_window_t window;
	xcb_pixmap_t pixmap;
	xcb_gcontext_t gc;
	VALUE surface;
	uint16_t x;
	uint16_t y;
	uint16_t width;
	uint16_t height;
	uint16_t sur_width;
	uint16_t sur_height;
} miw_xcb_window_t;

xcb_connection_t *g_connection = NULL;
int g_connected = 0;
st_table *g_st_window;

ID id_draw;
ID id_mouse_moved;
ID id_mouse_down;
ID id_mouse_up;
ID id_key_down;
ID id_key_up;

ID id_frame_resized;
ID id_frame_moved;
ID id_quit_requested;

ID id_entered;
ID id_exited;
ID id_inside;
ID id_outside;

/* window type */
ID id_type;
ID id_normal;
ID id_dialog;
ID id_dropdown_menu;
ID id_popup_menu;
ID id_combo_box;
ID id_utility;
ID id_tooltip;

xcb_atom_t g_atom_wm_protocols = XCB_ATOM_NONE;
xcb_atom_t g_atom_wm_delete_window = XCB_ATOM_NONE;
xcb_atom_t g_atom_wm_change_state = XCB_ATOM_NONE;
xcb_atom_t g_atom_net_wm_window_type = XCB_ATOM_NONE;
xcb_atom_t g_atom_net_wm_name = XCB_ATOM_NONE;
xcb_atom_t g_atom_utf8_string = XCB_ATOM_NONE;

struct xkb_context *g_xkb_context;
uint32_t g_xkb_device_id;
struct xkb_keymap *g_xkb_keymap;
struct xkb_state *g_xkb_state;
uint8_t g_xkb_event;

static xcb_atom_t
miw_xcb_intern_atom(xcb_connection_t *c, const char *name)
{
	xcb_intern_atom_cookie_t cookie;
	xcb_intern_atom_reply_t *reply;
	xcb_atom_t ret = XCB_ATOM_NONE;

	cookie = xcb_intern_atom(c, 1, strlen(name), name);
	reply = xcb_intern_atom_reply(c, cookie, NULL);
	if (reply) {
		ret = reply->atom;
		free(reply);
	}
	return ret;
}

static xcb_connection_t *
miw_xcb_connection(void)
{
	xcb_connection_t *c = g_connection;

	if (c == NULL)
		rb_raise(rb_eRuntimeError, "MiW::XCB is not yet initialized.");
	return c;
}

static xcb_screen_t *
miw_xcb_screen(xcb_connection_t *c)
{
	return xcb_setup_roots_iterator(xcb_get_setup(c)).data;
}

static xcb_visualtype_t *
miw_xcb_visualtype(xcb_connection_t *c)
{
	xcb_screen_t *screen = miw_xcb_screen(c);
	xcb_depth_iterator_t iter_depth;
	xcb_visualtype_iterator_t iter_visual;

	for (iter_depth = xcb_screen_allowed_depths_iterator(screen);
		 iter_depth.rem;
		 xcb_depth_next(&iter_depth)) {
		if (iter_depth.data->depth != screen->root_depth)
			continue;
		for (iter_visual = xcb_depth_visuals_iterator(iter_depth.data);
			 iter_visual.rem;
			 xcb_visualtype_next(&iter_visual))
			if (iter_visual.data->visual_id == screen->root_visual)
				return iter_visual.data;
	}
	return NULL;
}

static void
miw_xcb_win_mark(void *ptr)
{
	miw_xcb_window_t *w = (miw_xcb_window_t *)ptr;
	if (w->surface != Qnil)
		rb_gc_mark(w->surface);
}

static void
miw_xcb_win_free(void *ptr)
{
	cairo_surface_t *surface;
	miw_xcb_window_t *w = (miw_xcb_window_t *)ptr;
	xcb_connection_t *c = miw_xcb_connection();

	if (w->surface != Qnil) {
		surface = (cairo_surface_t *)DATA_PTR(w->surface);
		cairo_surface_finish(surface);
	}
	if (w->window) {
		xcb_free_pixmap(c, w->pixmap);
		xcb_free_gc(c, w->gc);
		xcb_destroy_window(c, w->window);
		xcb_flush(c);
	}
	xfree(ptr);
}

static VALUE
miw_xcb_win_alloc(VALUE klass)
{
	miw_xcb_window_t *w;
	VALUE self = Data_Make_Struct(klass, miw_xcb_window_t,
								  miw_xcb_win_mark, miw_xcb_win_free, w);
	w->surface = Qnil;
	return self;
}

static void
miw_xcb_surface_size(uint16_t width,   uint16_t height,
					 uint16_t *pwidth, uint16_t *pheight)
{
	if (width > 0)
		*pwidth = ((width - 1) / MIW_XCB_PIXMAP_GRID + 1) * MIW_XCB_PIXMAP_GRID;
	else
		*pwidth = MIW_XCB_PIXMAP_GRID;
	if (height > 0)
		*pheight = ((height - 1) / MIW_XCB_PIXMAP_GRID + 1) * MIW_XCB_PIXMAP_GRID;
	else
		*pheight = MIW_XCB_PIXMAP_GRID;
}

static void
miw_xcb_surface_free(void *ptr)
{
	cairo_surface_t *surface = (cairo_surface_t *)ptr;
	if(surface)
		cairo_surface_destroy(surface);
}

static xcb_pixmap_t
miw_xcb_create_pixmap(xcb_connection_t *c, uint16_t width, uint16_t height)
{
	xcb_pixmap_t pixmap;
	xcb_screen_t *screen = miw_xcb_screen(c);

	pixmap = xcb_generate_id(c);
	xcb_create_pixmap(c, screen->root_depth, pixmap, screen->root,
					  width, height);
	return pixmap;
}

static VALUE
miw_xcb_create_surface(xcb_connection_t *c,
					   uint16_t width, uint16_t height, xcb_pixmap_t *p_pixmap)
{
	VALUE result;
	VALUE m_cairo, c_surface;
	cairo_surface_t *surface;
	xcb_pixmap_t pixmap;

	m_cairo = rb_const_get(rb_mKernel, rb_intern("Cairo"));
	c_surface = rb_const_get(m_cairo, rb_intern("XCBSurface"));
	pixmap = miw_xcb_create_pixmap(c, width, height);
	surface = cairo_xcb_surface_create(c, pixmap, miw_xcb_visualtype(c),
									   width, height);
	result = Data_Wrap_Struct(c_surface, NULL, miw_xcb_surface_free, surface);
	*p_pixmap = pixmap;
	return result;
}

static void
miw_xcb_reallocate_pixmap(miw_xcb_window_t *w, xcb_connection_t *c,
						  uint16_t width, uint16_t height)
{
	cairo_surface_t *surface;
	xcb_pixmap_t pixmap = miw_xcb_create_pixmap(c, width, height);

	xcb_free_pixmap(c, w->pixmap);
	xcb_flush(c);
	surface = (cairo_surface_t *)DATA_PTR(w->surface);
	cairo_xcb_surface_set_drawable(surface, pixmap, width, height);
	w->pixmap = pixmap;
	w->sur_width = width;
	w->sur_height = height;
}

static void
miw_xcb_reallocate_pixmap_if_needed(miw_xcb_window_t *w, xcb_connection_t *c,
									 uint16_t width, uint16_t height)
{
	uint16_t new_width, new_height;

	if (w->sur_width     < width || w->sur_height     < height ||
		w->sur_width / 2 > width || w->sur_height / 2 > height) {
		miw_xcb_surface_size(width, height,
							 &new_width, &new_height);
		miw_xcb_reallocate_pixmap(w, c, new_width, new_height);
	}
}

static void
miw_xcb_create_window(miw_xcb_window_t *w, xcb_connection_t *c,
					  uint16_t x, uint16_t y, uint16_t width, uint16_t height)
{
	xcb_window_t window = 0;
	uint32_t mask;
	uint32_t value[2];
	xcb_screen_t *screen;
	xcb_pixmap_t pixmap;
	xcb_gcontext_t gc;
	xcb_intern_atom_cookie_t cookie;
	xcb_intern_atom_reply_t* atom_reply;
	VALUE surface;
	uint16_t sur_width, sur_height;

	screen = miw_xcb_screen(c);
	mask = XCB_CW_BACK_PIXMAP | XCB_CW_EVENT_MASK;
	value[0] = XCB_BACK_PIXMAP_NONE;
	value[1] =
		XCB_EVENT_MASK_EXPOSURE          |
		XCB_EVENT_MASK_BUTTON_PRESS      | XCB_EVENT_MASK_BUTTON_RELEASE   |
		XCB_EVENT_MASK_POINTER_MOTION    | XCB_EVENT_MASK_BUTTON_MOTION    |
		XCB_EVENT_MASK_ENTER_WINDOW      | XCB_EVENT_MASK_LEAVE_WINDOW     |
		XCB_EVENT_MASK_KEY_PRESS         | XCB_EVENT_MASK_KEY_RELEASE      |
		XCB_EVENT_MASK_VISIBILITY_CHANGE | XCB_EVENT_MASK_STRUCTURE_NOTIFY |
		XCB_EVENT_MASK_FOCUS_CHANGE      | XCB_EVENT_MASK_PROPERTY_CHANGE  |
		XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY ;
	window = xcb_generate_id(c);
	xcb_create_window(c, XCB_COPY_FROM_PARENT,
					  window, screen->root,
					  x, y, width, height,
					  0, XCB_WINDOW_CLASS_INPUT_OUTPUT,
					  screen->root_visual,
					  mask,
					  value);

	if (g_atom_wm_protocols && g_atom_wm_delete_window)
		xcb_change_property(c, XCB_PROP_MODE_REPLACE, window,
							g_atom_wm_protocols, XCB_ATOM_ATOM,
							32, 1, &g_atom_wm_delete_window);

	miw_xcb_surface_size(width, height, &sur_width, &sur_height);
	surface = miw_xcb_create_surface(c, sur_width, sur_height, &pixmap);
	gc = xcb_generate_id(c);
	xcb_create_gc(c, gc, window, 0, NULL);

	xcb_flush(c);
	w->window = window;
	w->pixmap = pixmap;
	w->gc = gc;
	w->surface = surface;
	w->x = x;
	w->y = y;
	w->width = width;
	w->height = height;
	w->sur_width = sur_width;
	w->sur_height = sur_height;
}

static VALUE
miw_xcb_win_initialize(VALUE self,
					   VALUE x, VALUE y, VALUE width, VALUE height,
					   VALUE opt)
{
	miw_xcb_window_t *w = DATA_PTR(self);
	
	if (w->window != 0)
		rb_raise(rb_eRuntimeError, "initialize called twice");
	miw_xcb_create_window(w, miw_xcb_connection(),
						  NUM2UINT(x), NUM2UINT(y),
						  NUM2UINT(width), NUM2UINT(height));
	st_insert(g_st_window, (st_data_t)w->window, (st_data_t)self);
	return self;
}

static VALUE
miw_xcb_win_surface(VALUE self)
{
	miw_xcb_window_t *w = (miw_xcb_window_t *)DATA_PTR(self);
	 
	if (w->window == 0)
		rb_raise(rb_eRuntimeError, "window is not initialized");
	return w->surface;
}

static VALUE
miw_xcb_win_sync(VALUE self, VALUE x, VALUE y, VALUE width, VALUE height)
{
	miw_xcb_window_t *w = (miw_xcb_window_t *)DATA_PTR(self);
	if (w->window && w->pixmap) {
		xcb_connection_t *c = miw_xcb_connection();
		xcb_copy_area(c,
					  w->pixmap,
					  w->window,
					  w->gc,
					  NUM2INT(x), NUM2INT(y), NUM2INT(x), NUM2INT(y),
					  NUM2INT(width), NUM2INT(height));
		xcb_flush(c);
		return Qtrue;
	}
	return Qfalse;
}

static VALUE
miw_xcb_win_show(VALUE self)
{
	miw_xcb_window_t *w = (miw_xcb_window_t *)DATA_PTR(self);
	xcb_connection_t *c = miw_xcb_connection();
	if (w->window) {
		xcb_map_window(c, w->window);
		xcb_flush(c);
	}
	return Qnil;
}

static VALUE
miw_xcb_win_hide(VALUE self)
{
	miw_xcb_window_t *w = (miw_xcb_window_t *)DATA_PTR(self);
	xcb_connection_t *c = miw_xcb_connection();
	if (w->window) {
		xcb_unmap_window(c, w->window);
		xcb_flush(c);
	}
	return Qnil;
}

static VALUE
miw_xcb_win_minimize(VALUE self)
{
	miw_xcb_window_t *w = (miw_xcb_window_t *)DATA_PTR(self);
	xcb_connection_t *c = miw_xcb_connection();
	xcb_client_message_event_t event;
	xcb_window_t root = miw_xcb_screen(c)->root;
	if (w->window) {
		event.response_type = XCB_CLIENT_MESSAGE;
		event.format = 32;
		event.sequence = 0;
		event.window = w->window;
		event.type = g_atom_wm_change_state;
		event.data.data32[0] = IconicState;
		xcb_send_event(c, 0, root, 0, (const char*)&event);
		return Qtrue;
	}
	return Qfalse;
}

static VALUE
miw_xcb_win_title_set(VALUE self, VALUE title)
{
	miw_xcb_window_t *w = (miw_xcb_window_t *)DATA_PTR(self);
	xcb_connection_t *c = miw_xcb_connection();
	if (w->window) {
		size_t len = RSTRING_LEN(title);
		xcb_change_property(c, XCB_PROP_MODE_REPLACE, w->window,
							g_atom_net_wm_name, g_atom_utf8_string,
							8, len, StringValuePtr(title));
		xcb_flush(c);
	}
	return Qnil;
}

static VALUE
miw_xcb_win_title_get(VALUE self)
{
	return Qnil;
}

static VALUE
miw_xcb_win_pos(VALUE self)
{
	miw_xcb_window_t *w = (miw_xcb_window_t *)DATA_PTR(self);
	VALUE x = INT2FIX(w->x);
	VALUE y = INT2FIX(w->y);
	return rb_ary_new_from_args(2, x, y);
}

static VALUE
miw_xcb_win_size(VALUE self)
{
	miw_xcb_window_t *w = (miw_xcb_window_t *)DATA_PTR(self);
	VALUE width = INT2FIX(w->width);
	VALUE height = INT2FIX(w->height);
	return rb_ary_new_from_args(2, width, height);
}

static VALUE
miw_xcb_win_update(VALUE self, VALUE x, VALUE y, VALUE width, VALUE height)
{
	miw_xcb_window_t *w = (miw_xcb_window_t *)DATA_PTR(self);
	xcb_connection_t *c = miw_xcb_connection();
	xcb_expose_event_t *e;
	if (w->window) {
		e = calloc(1, 32);
		e->response_type = XCB_EXPOSE;
		e->window = w->window;
		e->x = NUM2UINT(x);
		e->y = NUM2UINT(y);
		e->width = NUM2UINT(width);
		e->height = NUM2UINT(height);
		e->count = 1; /* ?? */
		xcb_send_event(c, 0, w->window, XCB_EVENT_MASK_EXPOSURE, (const char*)e);
		xcb_flush(c);
		free(e);
		return Qtrue;
	}
	return Qfalse;
}

static VALUE
miw_xcb_win_grab_pointer(VALUE self)
{
	miw_xcb_window_t *w = (miw_xcb_window_t *)DATA_PTR(self);
	xcb_connection_t *c = miw_xcb_connection();
	VALUE ret = Qfalse;
	if (w->window) {
		xcb_grab_pointer_cookie_t cookie;
		xcb_grab_pointer_reply_t *reply;
		cookie =
			xcb_grab_pointer(c,
							 0,
							 w->window,
							 XCB_EVENT_MASK_BUTTON_RELEASE |
							 XCB_EVENT_MASK_POINTER_MOTION,
							 XCB_GRAB_MODE_ASYNC,
							 XCB_GRAB_MODE_ASYNC,
							 XCB_NONE,
							 XCB_NONE,
							 XCB_CURRENT_TIME);
		reply = xcb_grab_pointer_reply(c, cookie, NULL);
		if (reply) {
			printf("reply->status: %d\n", reply->status);
			if (reply->status == XCB_GRAB_STATUS_SUCCESS)
				ret = Qtrue;
			free(reply);
		}
	}
	return ret;
}

static VALUE
miw_xcb_win_ungrab_pointer(VALUE self)
{
	miw_xcb_window_t *w = (miw_xcb_window_t *)DATA_PTR(self);
	xcb_connection_t *c = miw_xcb_connection();
	if (w->window) {
		xcb_void_cookie_t cookie = xcb_ungrab_pointer(c, XCB_CURRENT_TIME);
		xcb_flush(c);
		return Qtrue;
	}
	return Qfalse;
}

static VALUE
miw_xcb_default_hook0(VALUE self)
{
	return Qnil;
}

static VALUE
miw_xcb_default_hook2(VALUE self, VALUE a0, VALUE a1)
{
	return Qnil;
}

static VALUE
miw_xcb_default_hook3(VALUE self, VALUE a0, VALUE a1, VALUE a2)
{
	return Qnil;
}

static VALUE
miw_xcb_default_hook4(VALUE self, VALUE a0, VALUE a1, VALUE a2, VALUE a3)
{
	return Qnil;
}

static VALUE
miw_xcb_default_hook5(VALUE self, VALUE a0, VALUE a1, VALUE a2, VALUE a3, VALUE a4)
{
	return Qnil;
}

static VALUE
miw_xcb_window_lookup(xcb_window_t window)
{
	VALUE answer = Qnil;
	int status = st_lookup(g_st_window, (st_data_t)window, (st_data_t *)&answer);
	if (status)
		return answer;
	return Qnil;
}

static void
miw_xcb_on_expose(xcb_generic_event_t *event)
{
	xcb_expose_event_t *e = (xcb_expose_event_t *)event;
	xcb_window_t window = e->window;
	VALUE target = miw_xcb_window_lookup(window);
	VALUE force = Qfalse;

	if (target != Qnil)
		rb_funcall(target, id_draw, 4,
				   INT2FIX(e->x), INT2FIX(e->y),
				   INT2FIX(e->width), INT2FIX(e->height));
}

static void
miw_xcb_on_motion_notify(xcb_generic_event_t *event)
{
	xcb_motion_notify_event_t *e = (xcb_motion_notify_event_t *)event;
	xcb_window_t window = e->event;
	VALUE target = miw_xcb_window_lookup(window);

	if (target != Qnil)
		rb_funcall(target, id_mouse_moved, 4,
				   INT2FIX(e->event_x), INT2FIX(e->event_y),
				   ID2SYM(id_inside), Qnil);
}

static void
miw_xcb_on_enter_notify(xcb_generic_event_t *event)
{
	xcb_enter_notify_event_t *e = (xcb_enter_notify_event_t *)event;
	xcb_window_t window = e->event;
	VALUE target = miw_xcb_window_lookup(window);

	if (target != Qnil)
		rb_funcall(target, id_mouse_moved, 4,
				   INT2FIX(e->event_x), INT2FIX(e->event_y),
				   ID2SYM(id_entered), Qnil);
}

static void
miw_xcb_on_leave_notify(xcb_generic_event_t *event)
{
	xcb_leave_notify_event_t *e = (xcb_leave_notify_event_t *)event;
	xcb_window_t window = e->event;
	VALUE target = miw_xcb_window_lookup(window);

	if (target != Qnil)
		rb_funcall(target, id_mouse_moved, 4,
				   INT2FIX(e->event_x), INT2FIX(e->event_y),
				   ID2SYM(id_exited), Qnil);
}

static void
miw_xcb_on_button_press(xcb_generic_event_t *event)
{
	xcb_button_press_event_t *e = (xcb_button_press_event_t *)event;
	xcb_window_t window = e->event;
	VALUE target = miw_xcb_window_lookup(window);

	if (target != Qnil)
		rb_funcall(target, id_mouse_down, 4,
				   INT2FIX(e->event_x), INT2FIX(e->event_y),
				   INT2FIX(e->detail), INT2FIX(e->state));
}

static void
miw_xcb_on_button_release(xcb_generic_event_t *event)
{
	xcb_button_release_event_t *e = (xcb_button_release_event_t *)event;
	xcb_window_t window = e->event;
	VALUE target = miw_xcb_window_lookup(window);

	if (target != Qnil)
		rb_funcall(target, id_mouse_up, 4,
				   INT2FIX(e->event_x), INT2FIX(e->event_y),
				   INT2FIX(e->detail), INT2FIX(e->state));
}

static void
miw_xcb_on_key_press(xcb_generic_event_t *event)
{
	xkb_keysym_t keysym;
	xcb_key_press_event_t *e = (xcb_key_press_event_t *)event;
	xcb_window_t window = e->event;
	VALUE target = miw_xcb_window_lookup(window);

	if (target != Qnil) {
		keysym = xkb_state_key_get_one_sym(g_xkb_state, e->detail);
		rb_funcall(target, id_key_down, 2, UINT2NUM(keysym), INT2NUM(e->state));
	}
}

static void
miw_xcb_on_key_release(xcb_generic_event_t *event)
{
	xkb_keysym_t keysym;
	xcb_key_release_event_t *e = (xcb_key_release_event_t *)event;
	xcb_window_t window = e->event;
	VALUE target = miw_xcb_window_lookup(window);

	if (target != Qnil) {
		keysym = xkb_state_key_get_one_sym(g_xkb_state, e->detail);
		rb_funcall(target, id_key_up, 2, UINT2NUM(keysym), INT2NUM(e->state));
	}
}

static void
miw_xcb_on_configure_notify(xcb_generic_event_t *event)
{
	xcb_configure_notify_event_t *e = (xcb_configure_notify_event_t *)event;
	xcb_window_t window = e->window;
	VALUE target = miw_xcb_window_lookup(window);
	miw_xcb_window_t *w;

	if (target != Qnil) {
		w = (miw_xcb_window_t *)DATA_PTR(target);
		if (w->x != e->x || w->y != e->y) {
			w->x = e->x;
			w->y = e->y;
			rb_funcall(target, id_frame_moved, 2,
					   INT2FIX(e->x), INT2FIX(e->y));
		}
		if (w->width != e->width || w->height != e->height) {
			w->width = e->width;
			w->height = e->height;
			miw_xcb_reallocate_pixmap_if_needed(w, miw_xcb_connection(),
												e->width, e->height);
			rb_funcall(target, id_frame_resized, 2,
					   INT2FIX(e->width), INT2FIX(e->height));
		}
	}
}

static void
miw_xcb_on_unmap_notify(xcb_generic_event_t *event)
{
	xcb_unmap_notify_event_t *e = (xcb_unmap_notify_event_t *)event;
	xcb_window_t window = e->window;
	VALUE target = miw_xcb_window_lookup(window);
	miw_xcb_window_t *w;

	if (target != Qnil) ;
}

static void
miw_xcb_on_client_message(xcb_generic_event_t *event)
{
	xcb_client_message_event_t *e = (xcb_client_message_event_t *)event;
	xcb_window_t window = e->window;
	VALUE target = miw_xcb_window_lookup(window);

	if (target != Qnil) {
		if(e->data.data32[0] == g_atom_wm_delete_window)
			rb_funcall(target, id_quit_requested, 0);
	}
}

static void
miw_xcb_xkb_update()
{
	xcb_connection_t *c = miw_xcb_connection();

	if (g_xkb_keymap)
		xkb_keymap_unref(g_xkb_keymap);
	if (g_xkb_state)
		xkb_state_unref(g_xkb_state);

	g_xkb_device_id = xkb_x11_get_core_keyboard_device_id(c);
	if (g_xkb_device_id == -1)
		rb_raise(rb_eRuntimeError, "failed to get keyboard device id");
	g_xkb_keymap = xkb_x11_keymap_new_from_device(g_xkb_context, c,
												  g_xkb_device_id,
												  XKB_KEYMAP_COMPILE_NO_FLAGS);
	if (!g_xkb_keymap)
		rb_raise(rb_eRuntimeError, "failed to get keymap");

	g_xkb_state = xkb_x11_state_new_from_device(g_xkb_keymap, c,
												g_xkb_device_id);
	if (!g_xkb_state)
		rb_raise(rb_eRuntimeError, "failed to allocate an xkb state");
}

static VALUE
miw_xcb_s_setup(VALUE m_xcb)
{
	int err;
	xcb_connection_t *c = g_connection;
    xcb_void_cookie_t cookie;
	xcb_generic_error_t *xcb_error;

	if (c != NULL)
		rb_raise(rb_eRuntimeError, "setup called twice");

	c = xcb_connect(NULL, NULL);
	err = xcb_connection_has_error(c);
	if (err) {
		xcb_disconnect(c);
		rb_raise(rb_eRuntimeError, "xcb_connection error: %d", err);
	}
	g_atom_wm_protocols = miw_xcb_intern_atom(c, "WM_PROTOCOLS");
	g_atom_wm_delete_window = miw_xcb_intern_atom(c, "WM_DELETE_WINDOW");
	g_atom_wm_change_state = miw_xcb_intern_atom(c, "WM_CHANGE_STATE");
	g_atom_net_wm_name = miw_xcb_intern_atom(c, "_NET_WM_NAME");
	g_atom_net_wm_window_type = miw_xcb_intern_atom(c, "_NET_WM_WINDOW_TYPE");
	g_atom_utf8_string = miw_xcb_intern_atom(c, "UTF8_STRING");
	g_connection = c;
	g_connected ++;

	g_xkb_context = xkb_context_new(XKB_CONTEXT_NO_FLAGS);
	if (!g_xkb_context)
		rb_raise(rb_eRuntimeError, "failed xcb_context_new");

	err = xkb_x11_setup_xkb_extension(c,
									  XKB_X11_MIN_MAJOR_XKB_VERSION,
									  XKB_X11_MIN_MINOR_XKB_VERSION,
									  XKB_X11_SETUP_XKB_EXTENSION_NO_FLAGS,
									  NULL, NULL, &g_xkb_event, NULL);
	if(err == 0)
		rb_raise(rb_eRuntimeError, "failed to setup xkb");

	miw_xcb_xkb_update();
	
	cookie = xcb_xkb_select_events(c, XCB_XKB_ID_USE_CORE_KBD,
								   MIW_XCB_XKB_EVENT_TYPE, 0,
								   MIW_XCB_XKB_EVENT_TYPE, 0, 0, NULL);
	xcb_error = xcb_request_check(c, cookie);
	if (xcb_error)
		rb_raise(rb_eRuntimeError, "failed to select events");
	
	return Qtrue;
}

static VALUE
miw_xcb_s_file_descriptor(VALUE m_xcb)
{
	xcb_connection_t *c = miw_xcb_connection();
	int fd = xcb_get_file_descriptor(c);
	
	return INT2NUM(fd);
}

static void
miw_xcb_on_xkb_event(xcb_generic_event_t *event)
{
	xcb_xkb_state_notify_event_t *xkb_event =
		(xcb_xkb_state_notify_event_t *)event;

	switch (xkb_event->xkbType) {
	case XCB_XKB_NEW_KEYBOARD_NOTIFY:
	case XCB_XKB_MAP_NOTIFY:
		miw_xcb_xkb_update();
		break;
	case XCB_XKB_STATE_NOTIFY:
		xkb_state_update_mask(g_xkb_state,
							  xkb_event->baseMods,
							  xkb_event->latchedMods,
							  xkb_event->lockedMods,
							  xkb_event->baseGroup,
							  xkb_event->latchedGroup,
							  xkb_event->lockedGroup);
		break;
	}
}

static void
miw_xcb_process_single_event(xcb_generic_event_t *event, xcb_connection_t *c)
{
	switch (event->response_type & 0x7f) {
	case XCB_EXPOSE:
		miw_xcb_on_expose(event);
		xcb_flush(c);
		break;

	case XCB_MOTION_NOTIFY:
		miw_xcb_on_motion_notify(event);
		break;

	case XCB_ENTER_NOTIFY:
		miw_xcb_on_enter_notify(event);
		break;

	case XCB_LEAVE_NOTIFY:
		miw_xcb_on_leave_notify(event);
		break;

	case XCB_BUTTON_PRESS:
		miw_xcb_on_button_press(event);
		break;

	case XCB_BUTTON_RELEASE:
		miw_xcb_on_button_release(event);
		break;

	case XCB_KEY_PRESS:
		miw_xcb_on_key_press(event);
		break;

	case XCB_KEY_RELEASE:
		miw_xcb_on_key_release(event);
		break;
		
	case XCB_CONFIGURE_NOTIFY:
		miw_xcb_on_configure_notify(event);
		break;

	case XCB_UNMAP_NOTIFY:
		miw_xcb_on_unmap_notify(event);
		break;

	case XCB_CLIENT_MESSAGE:
		miw_xcb_on_client_message(event);
		break;
		
	default:
		if ((event->response_type & 0x7f) == g_xkb_event)
			miw_xcb_on_xkb_event(event);
		break;
	}
}

static VALUE
miw_xcb_s_process_event(VALUE m_xcb)
{
	xcb_generic_event_t *event;
	xcb_connection_t *c = miw_xcb_connection();

	event = xcb_poll_for_event(c);
	if (event)
		miw_xcb_process_single_event(event, c);

	return Qnil;
}

#define DEFINE_ID(name) id_##name = rb_intern(#name)
#define DEFAULT_HOOK(name, a) rb_define_method(c, #name, miw_xcb_default_hook##a, a)

void
miw_xcb_init()
{
	VALUE m_miw, m_xcb, c;

	if (rb_const_defined(rb_mKernel, rb_intern("MiW")))
		m_miw = rb_const_get(rb_mKernel, rb_intern("MiW"));
	else
		m_miw = rb_define_module("MiW");

	m_xcb = rb_define_module_under(m_miw, "XCB");
	rb_define_singleton_method(m_xcb, "setup", miw_xcb_s_setup, 0);
	rb_define_singleton_method(m_xcb, "process_event", miw_xcb_s_process_event, 0);
	rb_define_singleton_method(m_xcb, "file_descriptor", miw_xcb_s_file_descriptor, 0);

	c = rb_define_class_under(m_xcb, "Window", rb_cData);
	rb_define_alloc_func(c, miw_xcb_win_alloc);
	rb_define_method(c, "initialize", miw_xcb_win_initialize, 5);
	rb_define_method(c, "show", miw_xcb_win_show, 0);
	rb_define_method(c, "hide", miw_xcb_win_hide, 0);
	rb_define_method(c, "minimize", miw_xcb_win_minimize, 0);
	rb_define_method(c, "title=", miw_xcb_win_title_set, 1);
	rb_define_method(c, "title", miw_xcb_win_title_get, 0);
	rb_define_method(c, "surface", miw_xcb_win_surface, 0);
	rb_define_method(c, "sync", miw_xcb_win_sync, 4);
	rb_define_method(c, "pos", miw_xcb_win_pos, 0);
	rb_define_method(c, "size", miw_xcb_win_size, 0);
	rb_define_method(c, "update", miw_xcb_win_update, 4);
	rb_define_method(c, "grab_pointer", miw_xcb_win_grab_pointer, 0);
	rb_define_method(c, "ungrab_pointer", miw_xcb_win_ungrab_pointer, 0);

	DEFAULT_HOOK(draw, 4);
	DEFAULT_HOOK(mouse_moved, 4);
	DEFAULT_HOOK(mouse_down, 4);
	DEFAULT_HOOK(mouse_up, 4);
	DEFAULT_HOOK(key_up, 2);
	DEFAULT_HOOK(key_down, 2);
	DEFAULT_HOOK(frame_resized, 2);
	DEFAULT_HOOK(frame_moved, 2);
	DEFAULT_HOOK(quit_requested, 0);
	
	DEFINE_ID(draw);
	DEFINE_ID(mouse_moved);
	DEFINE_ID(mouse_down);
	DEFINE_ID(mouse_up);
	DEFINE_ID(key_down);
	DEFINE_ID(key_up);
	DEFINE_ID(frame_resized);
	DEFINE_ID(frame_moved);
	DEFINE_ID(quit_requested);

	DEFINE_ID(entered);
	DEFINE_ID(exited);
	DEFINE_ID(inside);
	DEFINE_ID(outside);

	DEFINE_ID(type);
	DEFINE_ID(normal);
	DEFINE_ID(dialog);
	DEFINE_ID(dropdown_menu);
	DEFINE_ID(popup_menu);
	DEFINE_ID(combo_box);
	DEFINE_ID(utility);
	DEFINE_ID(tooltip);

	g_st_window = st_init_numtable();
}
