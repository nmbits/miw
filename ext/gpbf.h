#ifndef GPBF_H__
#define GPBF_H__

#include <stdint.h>

typedef struct gpbf_tag gpbf_t;
typedef size_t gpbf_index_t;
typedef size_t gpbf_linum_t;

gpbf_t *gpbf_new();
void    gpbf_free(gpbf_t *);
int     gpbf_set_eol(gpbf_t *, uint8_t);
uint8_t gpbf_get_eol(const gpbf_t *);
int     gpbf_line_to_index(gpbf_t *, const gpbf_linum_t, gpbf_index_t *);
int     gpbf_line_from_index(gpbf_t *, gpbf_index_t, gpbf_linum_t *);
int     gpbf_line_length(gpbf_t *, const gpbf_linum_t, size_t *);
size_t  gpbf_count_lines(gpbf_t *);
int     gpbf_insert(gpbf_t *, gpbf_index_t, size_t, const uint8_t *);
int     gpbf_copy_text(gpbf_t *, gpbf_index_t, size_t, uint8_t *);
size_t  gpbf_length(const gpbf_t *);
int     gpbf_delete(gpbf_t *, gpbf_index_t, size_t);
void    gpbf_clear(gpbf_t *);
int     gpbf_adjust_index_forward(const gpbf_t *, gpbf_index_t, gpbf_index_t *);
int     gpbf_adjust_index_backward(const gpbf_t *, gpbf_index_t, gpbf_index_t *);

size_t  gpbf_length_to_next_line(gpbf_t *, const gpbf_index_t index);
gpbf_index_t gpbf_line_head_index(const gpbf_t *, gpbf_index_t);

#endif
