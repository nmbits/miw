#include <ruby.h>
#include "gpbf.h"

#define NUM2LINUM RB_NUM2ULONG
#define LINUM2NUM RB_ULONG2NUM

#define NUM2INDEX RB_NUM2ULONG
#define INDEX2NUM RB_ULONG2NUM

static void
miw_txbf__free(gpbf_t *gpbf)
{
	gpbf_free(gpbf);
}

static size_t
miw_txbf__size(gpbf_t *gpbf)
{
	size_t ret = 0;
	// ret = sizeof(gpbf_t);
	ret += gpbf_length(gpbf);
	return ret;
}

const rb_data_type_t miw_txbf_data_type = {
	"miw/text_buffer",
	{
		0,
		(void (*)(void *))miw_txbf__free,
		(size_t (*)(const void *))miw_txbf__size
	}
};

static VALUE
miw_txbf_alloc(VALUE class_)
{
	gpbf_t *gpbf = gpbf_new();
	if (!gpbf)
		rb_raise(rb_eNoMemError, "no enough memory for TextBuffer");
	return TypedData_Wrap_Struct(class_, &miw_txbf_data_type, (void *)gpbf);
}

static VALUE
miw_txbf_initialize(int argc, VALUE *argv, VALUE self)
{
	VALUE eol_;

	gpbf_t *gpbf = (gpbf_t *)DATA_PTR(self);
	rb_scan_args(argc, argv, "01", &eol_);
	if (!RB_NIL_P(eol_)) {
		unsigned int eol = RB_NUM2UINT(eol_);
		int ret = gpbf_set_eol(gpbf, eol);
		if (ret == 0)
			rb_raise(rb_eArgError, "unsupported eol: %u", eol);
	}
	return self;
}

static VALUE
miw_txbf_insert(VALUE self, VALUE index_, VALUE text_)
{
	gpbf_t *gpbf = (gpbf_t *)DATA_PTR(self);
	const uint8_t *text = (const uint8_t *)StringValuePtr(text_);
	size_t len = RSTRING_LEN(text_);
	gpbf_index_t index = NUM2INDEX(index_);
	int ret = gpbf_insert(gpbf, index, len, text);
	if (ret == 0)
		rb_raise(rb_eRuntimeError, "TBD");
	return Qnil;
}

typedef struct
{
	gpbf_t *gpbf;
	gpbf_index_t index;
	size_t len;
	uint8_t *out;
	int res;
} miw_txbf_text_copy_arg_t;

static VALUE
miw_txbf_text_copy(VALUE arg_)
{
	miw_txbf_text_copy_arg_t *arg = (miw_txbf_text_copy_arg_t *)arg_;
	arg->res = gpbf_copy_text(arg->gpbf, arg->index, arg->len, arg->out);
	return Qundef;
}

static VALUE
miw_txbf_text(int argc, VALUE *argv, VALUE self)
{
	VALUE index_, len_, text_;
	gpbf_index_t index;
	size_t len;
	miw_txbf_text_copy_arg_t arg;

	rb_scan_args(argc, argv, "21", &index_, &len_, &text_);
	len = NUM2SIZET(len_);
	index = NUM2INDEX(index_);
	
	if (RB_NIL_P(text_)) {
		text_ = rb_str_new(0, 0);
		rb_str_modify_expand(text_, len);
	} else {
		rb_check_type(text_, T_STRING);
		size_t clen = RSTRING_LEN(text_);
		if (clen >= len)
			rb_str_modify(text_);
		else
			rb_str_modify_expand(text_, len - clen);
	}
	arg.gpbf = (gpbf_t *)DATA_PTR(self);
	arg.index = index;
	arg.len = len;
	arg.out = RSTRING_PTR(text_);
	rb_str_locktmp(text_);
	rb_ensure(miw_txbf_text_copy, (VALUE)&arg, rb_str_unlocktmp, text_);
	// rb_str_locktmp_ensure(text_, miw_txbf_text_copy, (VALUE)&arg);
	if (!arg.res)
		rb_raise(rb_eRuntimeError, "something wrong with gpbf");
	rb_str_set_len(text_, len);
	return text_;
}

static VALUE
miw_txbf_line_to_index(VALUE self, VALUE linum_)
{
	gpbf_linum_t linum = NUM2LINUM(linum_);
	gpbf_index_t index;
	gpbf_t *gpbf = (gpbf_t *)DATA_PTR(self);

	if (!gpbf_line_to_index(gpbf, linum, &index))
		rb_raise(rb_eRangeError, "linum out of range");
	return INDEX2NUM(index);
}

static VALUE
miw_txbf_line_from_index(VALUE self, VALUE index_)
{
	gpbf_linum_t linum;
	gpbf_index_t index = NUM2INDEX(index_);
	gpbf_t *gpbf = (gpbf_t *)DATA_PTR(self);

	if (!gpbf_line_from_index(gpbf, index, &linum))
		rb_raise(rb_eRangeError, "index out of range");
	return LINUM2NUM(linum);
}

static VALUE
miw_txbf_line_head_index(VALUE self, VALUE index_)
{
	gpbf_index_t index = NUM2INDEX(index_);
	gpbf_t *gpbf = (gpbf_t *)DATA_PTR(self);

	return LINUM2NUM(gpbf_line_head_index(gpbf, index));
}

static VALUE
miw_txbf_length_to_next_line(VALUE self, VALUE index_)
{
	gpbf_index_t index = NUM2INDEX(index_);
	gpbf_t *gpbf = (gpbf_t *)DATA_PTR(self);

	return SIZET2NUM(gpbf_length_to_next_line(gpbf, index));
}

static VALUE
miw_txbf_line_length(VALUE self, VALUE linum_)
{
	gpbf_linum_t linum = NUM2LINUM(linum_);
	size_t size;
	gpbf_t *gpbf = (gpbf_t *)DATA_PTR(self);

	if (!gpbf_line_length(gpbf, linum, &size))
		rb_raise(rb_eRangeError, "linum out of range");
	return SIZET2NUM(size);
}

static VALUE
miw_txbf_count_lines(VALUE self)
{
	return SIZET2NUM(gpbf_count_lines((gpbf_t *)DATA_PTR(self)));
}

static VALUE
miw_txbf_length(VALUE self)
{
	return SIZET2NUM(gpbf_length((gpbf_t *)DATA_PTR(self)));
}

static VALUE
miw_txbf_delete(VALUE self, VALUE index_, VALUE len_)
{
	gpbf_t *gpbf = (gpbf_t *)DATA_PTR(self);
	gpbf_index_t index = NUM2INDEX(index_);
	size_t len = NUM2SIZET(len_);

	if (!gpbf_delete(gpbf, index, len))
		rb_raise(rb_eRangeError, "delete out of range");
	return Qnil;
}

static VALUE
miw_txbf_clear(VALUE self)
{
	gpbf_clear((gpbf_t *)DATA_PTR(self));
	return Qnil;
}


static VALUE
miw_txbf_adjust_index_forward(VALUE self, VALUE index_)
{
	gpbf_t *gpbf = (gpbf_t *)DATA_PTR(self);
	gpbf_index_t index = NUM2INDEX(index_);
	gpbf_index_t out;

	if (!gpbf_adjust_index_forward(gpbf, index, &out))
		rb_raise(rb_eRangeError, "index out of range");
	return INDEX2NUM(out);
}

static VALUE
miw_txbf_adjust_index_backward(VALUE self, VALUE index_)
{
	gpbf_t *gpbf = (gpbf_t *)DATA_PTR(self);
	gpbf_index_t index = NUM2INDEX(index_);
	gpbf_index_t out;

	if (!gpbf_adjust_index_backward(gpbf, index, &out))
		rb_raise(rb_eRangeError, "index out of range");
	return INDEX2NUM(out);
}

void
miw_txbf_init(void)
{
	VALUE m_miw, m_model, c;

	if (rb_const_defined(rb_mKernel, rb_intern("MiW")))
		m_miw = rb_const_get(rb_mKernel, rb_intern("MiW"));
	else
		m_miw = rb_define_module("MiW");

	if (rb_const_defined(m_miw, rb_intern("Model")))
		m_model = rb_const_get(m_miw, rb_intern("Model"));
	else
		m_model = rb_define_module_under(m_miw, "Model");

	c = rb_define_class_under(m_model, "TextBufferC", rb_cData);
	rb_define_alloc_func(c, miw_txbf_alloc);
	rb_define_method(c, "initialize", miw_txbf_initialize, -1);
	rb_define_method(c, "insert", miw_txbf_insert, 2);
	rb_define_method(c, "text", miw_txbf_text, -1);
	rb_define_method(c, "line_length", miw_txbf_line_length, 1);
	rb_define_method(c, "line_to_index", miw_txbf_line_to_index, 1);
	rb_define_method(c, "line_from_index", miw_txbf_line_from_index, 1);
	rb_define_method(c, "length_to_next_line", miw_txbf_length_to_next_line, 1);
	rb_define_method(c, "line_head_index", miw_txbf_line_head_index, 1);
	rb_define_method(c, "count_lines", miw_txbf_count_lines, 0);
	rb_define_method(c, "length", miw_txbf_length, 0);
	rb_define_method(c, "delete", miw_txbf_delete, 2);
	rb_define_method(c, "clear", miw_txbf_clear, 0);
	rb_define_method(c, "adjust_forward", miw_txbf_adjust_index_forward, 1);
	rb_define_method(c, "adjust_backward", miw_txbf_adjust_index_backward, 1);
}
