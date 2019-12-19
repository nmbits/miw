#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <limits.h>

#include "gpbf.h"

#define ALLOC_UNIT_TEXT 400

// TODO
#define MALLOC_MAX (ULONG_MAX >> 8)

#define CR 0x0d
#define LF 0x0a

#define EOL_UNIX 0
#define EOL_DOS  1

#define UTF8_MASK_1B (0x80)   /* 1000 0000 */
#define UTF8_BITS_1B (0x00)   /* 0xxx xxxx */
#define UTF8_MASK_MB (0xc0)   /* 1100 0000 */
#define UTF8_BITS_MB (0x80)   /* 10xx xxxx */
#define UTF8_MASK_2B (0xe0)   /* 1110 0000 */
#define UTF8_BITS_2B (0xc0)   /* 110x xxxx */
#define UTF8_MASK_3B (0xf0)   /* 1111 0000 */
#define UTF8_BITS_3B (0xe0)   /* 1110 xxxx */
#define UTF8_MASK_4B (0xf8)   /* 1111 1000 */
#define UTF8_BITS_4B (0xf0)   /* 1111 0xxx */

static int
gpbf_utf8_middle_p(uint8_t c)
{
	return ((c & UTF8_MASK_MB) == UTF8_BITS_MB);
}

#if 0
static size_t
gpbf_utf8_char_bytes(char c)
{
	if ((c & UTF8_MASK_1B) == UTF8_BITS_1B) return 1;
	if ((c & UTF8_MASK_2B) == UTF8_BITS_2B) return 2;
	if ((c & UTF8_MASK_3B) == UTF8_BITS_3B) return 3;
	if ((c & UTF8_MASK_4B) == UTF8_BITS_4B) return 4;
	return 0;
}
#endif

typedef struct gpbf_array_tag
{
	size_t element_size;
	size_t capacity;
	size_t num_elements;
	gpbf_index_t gap_begin;
	size_t gap_length;
	size_t alloc_unit;
	void *memory;
} gpbf_array_t;

typedef struct gpbf_line_tag
{
	gpbf_linum_t linum;
	gpbf_index_t index;
} gpbf_line_t;

typedef struct gpbf_tag
{
	gpbf_array_t *text;
	gpbf_line_t line_cache;
	uint8_t eol;
} gpbf_t;

#if 0
static size_t
gpbf_array_capacity(const gpbf_array_t *array)
{
	return array->capacity;
}
#endif

static size_t
gpbf_array_num_elements(const gpbf_array_t *array)
{
	return array->num_elements;
}

static void *
gpbf_array_top_address(const gpbf_array_t *array)
{
	return array->memory;
}

static size_t
gpbf_array_top_bytes(const gpbf_array_t *array)
{
	return array->gap_begin * array->element_size;
}

static void *
gpbf_array_gap_address(const gpbf_array_t *array)
{
	return gpbf_array_top_address(array) + gpbf_array_top_bytes(array);
}

static size_t
gpbf_array_gap_bytes(const gpbf_array_t *array)
{
	return array->gap_length * array->element_size;
}

static gpbf_index_t
gpbf_array_bottom_index(const gpbf_array_t *array)
{
	return array->gap_begin + array->gap_length;
}

static void *
gpbf_array_bottom_address(const gpbf_array_t *array)
{
	return gpbf_array_gap_address(array) + gpbf_array_gap_bytes(array);
}

static size_t
gpbf_array_bottom_elements(const gpbf_array_t *array)
{
	return array->capacity - gpbf_array_bottom_index(array);
}

static size_t
gpbf_array_bottom_bytes(const gpbf_array_t *array)
{
	return  gpbf_array_bottom_elements(array) * array->element_size;
}

#if 0
static uint32_t
gpbf_array_data_bytes(const gpbf_array_t *array)
{
	return array->num_elements * array->element_size;
}
#endif

#if 0
static int
gpbf_array_empty_p(const gpbf_array_t *array)
{
	return (array->num_elements == 0);
}
#endif

#if 0
static int
gpbf_array_top_empty_p(gpbf_array_t *array)
{
	return (array->gap_begin == 0);
}

static int
gpbf_array_bottom_empty_p(const gpbf_array_t *array)
{
	return (array->capacity == (array->gap_begin + array->gap_length));
}
#endif

static void *
gpbf_array_raw_index_to_address(const gpbf_array_t *array, gpbf_index_t raw_index)
{
	return array->memory + array->element_size * raw_index;
}

static gpbf_index_t
gpbf_array_index_to_raw_index(const gpbf_array_t *array, gpbf_index_t index)
{
	if (index >= array->gap_begin)
		index += array->gap_length;
	return index;
}

static void *
gpbf_array_index_to_address(const gpbf_array_t *array, gpbf_index_t index)
{
	gpbf_index_t raw_index = gpbf_array_index_to_raw_index(array, index);
	return gpbf_array_raw_index_to_address(array, raw_index);
}

static void
gpbf_array_copy_raw(const gpbf_array_t * array, void *dst, gpbf_index_t raw_index, size_t len)
{
	memmove(dst, gpbf_array_raw_index_to_address(array, raw_index),
			len * array->element_size);
}

static void
gpbf_array_copy_elements(gpbf_array_t *array, gpbf_index_t index, size_t num, void *dst)
{
	size_t len;

	if (num == 0)
		return;

	/* 1. from top */
	if (index < array->gap_begin) {
		len = array->gap_begin - index;
		if (len > num)
			len = num;
		gpbf_array_copy_raw(array, dst, index, len);
		if (num == len)
			return;
		num -= len;
		index += len;
		dst += len * array->element_size;
	}		

	/* 2. from bottom */
	gpbf_array_copy_raw(array, dst, index + array->gap_length, num);
}

static int
gpbf_array_move_gap(gpbf_array_t *array, gpbf_index_t index)
{
	size_t len;
	char *src, *dst;

	if (array->gap_begin == index)
		return 1;
	if (array->num_elements < index)
		return 0;
	if (array->gap_length == 0) {
		array->gap_begin = index;
		return 1;
	}
	if (index < array->gap_begin) {
		len = array->gap_begin - index;
		dst = gpbf_array_raw_index_to_address(array, gpbf_array_bottom_index(array) - len);
		src = gpbf_array_raw_index_to_address(array, index);
	} else {
		len = index - array->gap_begin;
		dst = gpbf_array_gap_address(array);
		src = gpbf_array_bottom_address(array);
	}
	memmove(dst, src, len * array->element_size);
	array->gap_begin = index;
	return 1;
}

static int
gpbf_array_extend_gap(gpbf_array_t *array, size_t min)
{
	if (min == 0)
		return 0;

	if (array->gap_length > min)
		return 1;

	size_t capacity_max = MALLOC_MAX / array->element_size;
	size_t capacity_rem = capacity_max - array->num_elements;

	if (capacity_rem < min)
		return 0;

	size_t new_gap_length =
		(capacity_rem - min < ALLOC_UNIT_TEXT ? capacity_rem : min + ALLOC_UNIT_TEXT);
	
	size_t new_capacity = array->num_elements + new_gap_length;
	void *new_mem = realloc(array->memory, array->element_size * new_capacity);
	if (new_mem == NULL)
		return 0;
	array->memory = new_mem;
	void *src = gpbf_array_bottom_address(array);
	void *dst = src + (new_gap_length - array->gap_length) * array->element_size;
	memmove(dst, src, gpbf_array_bottom_bytes(array));
	array->gap_length = new_gap_length;
	array->capacity = new_capacity;
	return 1;
}

static void
gpbf_array_shrink_gap(gpbf_array_t *array)
{
	if (array->gap_length < array->alloc_unit * 2)
		return;
	size_t new_gap_length = array->alloc_unit;
	size_t new_capacity = array->capacity - array->gap_length + new_gap_length;
	void *src = gpbf_array_bottom_address(array);
	void *dst = gpbf_array_raw_index_to_address(array, array->gap_begin + new_gap_length);
	memmove(dst, src, gpbf_array_bottom_bytes(array));
	array->memory = realloc(array->memory, new_capacity * array->element_size);
	array->gap_length = new_gap_length;
	array->capacity = new_capacity;
}

static int
gpbf_array_insert(gpbf_array_t *array, gpbf_index_t index, size_t num, const void *src)
{
	int ret = gpbf_array_move_gap(array, index);
	if (!ret)
		return 0;
	if (array->gap_length < num) {
		if (!gpbf_array_extend_gap(array, num))
			return 0;
	}
	void *dst = gpbf_array_gap_address(array);
	memmove(dst, src, num * array->element_size);
	array->gap_begin += num;
	array->gap_length -= num;
	array->num_elements += num;
	return 1;
}

static int
gpbf_array_delete(gpbf_array_t *array, gpbf_index_t index, size_t num)
{
	if (array->num_elements < index)
		return 0;

	if (array->num_elements - index < num)
		return 0;

	// TODO
	gpbf_array_move_gap(array, index);
	array->gap_length += num;
	array->num_elements -= num;
	gpbf_array_shrink_gap(array);
	return 1;
}

static gpbf_array_t *
gpbf_array_allocate(size_t element_size, size_t capacity, size_t alloc_unit)
{
	gpbf_array_t *array = (gpbf_array_t *)malloc(sizeof(gpbf_array_t));
	if (!array)
		return NULL;
	memset(array, 0, sizeof(gpbf_array_t));
	void *memory = malloc(element_size * capacity);
	if (!memory) {
		free(array);
		return NULL;
	}
	array->memory = memory;
	array->capacity = capacity;
	array->gap_length = capacity;
	array->element_size = element_size;
	array->alloc_unit = alloc_unit;
	return array;
}

static void
gpbf_array_free(gpbf_array_t *array)
{
	free(array->memory);
	free(array);
}

static void
gpbf_reset_line_cache(gpbf_t *gpbf)
{
	memset(&(gpbf->line_cache), 0, sizeof(gpbf_line_t));
}

gpbf_t *
gpbf_new()
{
	gpbf_t *gpbf = (gpbf_t *)malloc(sizeof(gpbf_t));
	if (!gpbf)
		return NULL;
	memset(gpbf, 0, sizeof(gpbf_t));
	gpbf->text = gpbf_array_allocate(1, ALLOC_UNIT_TEXT, ALLOC_UNIT_TEXT);
	if (!gpbf->text) {
		free(gpbf);
		return NULL;
	}
	return gpbf;
}

void
gpbf_free(gpbf_t *gpbf)
{
	gpbf_array_free(gpbf->text);
	free(gpbf);
}

int
gpbf_set_eol(gpbf_t *gpbf, uint8_t eol)
{
	switch (eol) {
	case EOL_UNIX:
	case EOL_DOS:
		gpbf->eol = eol;
		break;
	default:
		return 0;
	}
	gpbf_reset_line_cache(gpbf);
	return 1;
}

uint8_t
gpbf_get_eol(const gpbf_t *gpbf)
{
	return gpbf->eol;
}

static int
gpbf_line_to_index_backward(gpbf_t *gpbf, gpbf_linum_t ln, gpbf_index_t index, gpbf_index_t *out)
{
	gpbf_index_t min = (gpbf->eol == EOL_UNIX ? 0 : 1);
	int found = 0;

	while (index > min) {
		uint8_t *c = gpbf_array_index_to_address(gpbf->text, index - 1);
		if (*c == LF) {
			if (gpbf->eol == EOL_UNIX) {
				found = 1;
			} else {
				c = gpbf_array_index_to_address(gpbf->text, index - 2);
				if (*c == CR)
					found = 1;
			}
			if (found) {
				if (ln == 0) {
					*out = index;
					return 1;
				}
				ln--;
				found = 0;
			}
		}
		index--;
	}
	return 0;
}

static int
gpbf_line_to_index_forward(gpbf_t *gpbf, gpbf_linum_t ln, gpbf_index_t index, gpbf_index_t *out)
{
	uint8_t prevc = 0;

	while (index < gpbf_length(gpbf)) {
		uint8_t *c = gpbf_array_index_to_address(gpbf->text, index);
		index++;
		if ((*c == LF) && ((gpbf->eol == EOL_UNIX) || (prevc == CR))) {
			ln--;
			if (ln == 0) {
				*out = index;
				return 1;
			}
		}
		prevc = *c;
	}
	return 0;
}

int
gpbf_line_to_index(gpbf_t *gpbf, const gpbf_linum_t linum, gpbf_index_t *out)
{
	int ret;

	if (linum == 0) {
		*out = 0;
		return 1;
	}

	if (gpbf->line_cache.linum == linum) {
		*out = gpbf->line_cache.index;
		return 1;
	}

	gpbf_linum_t ln;
	gpbf_index_t index = gpbf->line_cache.index;

	if (gpbf->line_cache.linum < linum) {
		ln = linum - gpbf->line_cache.linum;
		ret = gpbf_line_to_index_forward(gpbf, ln, index, out);
	} else if (linum < gpbf->line_cache.linum / 2 ) {
		ret = gpbf_line_to_index_forward(gpbf, linum, 0, out);
	} else {
		ln = gpbf->line_cache.linum - linum;
		ret = gpbf_line_to_index_backward(gpbf, ln, index, out);
	}

	if (ret) {
		gpbf->line_cache.linum = linum;
		gpbf->line_cache.index = *out;
		return 1;
	}
	return 0;
}

size_t
gpbf_length_to_next_line(gpbf_t *gpbf, const gpbf_index_t index)
{
	size_t length = 0;
	uint8_t prevc = 0;

	while (index + length < gpbf_length(gpbf)) {
		uint8_t *c = gpbf_array_index_to_address(gpbf->text, index + length);
		length++;
		if ((*c == LF) && ((gpbf->eol == EOL_UNIX) || (prevc == CR)))
			return length;
		prevc = *c;
	}
	return 0;
}

gpbf_index_t
gpbf_line_head_index(const gpbf_t *gpbf, gpbf_index_t index)
{
	for (; index > 0; index--) {
		uint8_t *c = gpbf_array_index_to_address(gpbf->text, index - 1);
		if (*c != LF)
			continue;
		if (gpbf->eol == EOL_UNIX)
			break;
		if (index > 1) {
			c = gpbf_array_index_to_address(gpbf->text, index - 2);
			if (*c == CR)
				break;
		}
	}
	return index;
}

/*
 * args beg and end should be valid and adjusted before calling this
 * function.
 */
static size_t
gpbf_count_eol(gpbf_t *gpbf,
			   const gpbf_index_t beg, const gpbf_index_t end)
{
	size_t count = 0;
	uint8_t prevc = 0;

	for (gpbf_index_t cur = beg; cur < end; cur++) {
		uint8_t *c = gpbf_array_index_to_address(gpbf->text, cur);
		if ((*c == LF) && ((gpbf->eol == EOL_UNIX) || (prevc == CR))) {
			count++;
		}
		prevc = *c;
	}
	return count;
}

int
gpbf_line_from_index(gpbf_t *gpbf, gpbf_index_t index, gpbf_linum_t *out)
{
	int ret;

	if (index > gpbf_length(gpbf))
		return 0;

	gpbf_linum_t linum = gpbf->line_cache.linum;
	gpbf_index_t line_index = gpbf->line_cache.index;

	if (index <= line_index / 2) {
		*out = gpbf_count_eol(gpbf, 0, index);
	} else if (index < line_index) {
		gpbf_adjust_index_backward(gpbf, index, &index);
		*out = linum - gpbf_count_eol(gpbf, index, line_index);
	} else {
		*out = linum + gpbf_count_eol(gpbf, line_index, index);
	}
	return 1;
}

int
gpbf_line_length(gpbf_t *gpbf, const gpbf_linum_t linum, size_t *out)
{
	gpbf_index_t index;
	size_t len = 0;
	uint8_t prevc = 0;

	if (!gpbf_line_to_index(gpbf, linum, &index))
		return 0;

	while (index + len < gpbf_array_num_elements(gpbf->text)) {
		uint8_t *c = gpbf_array_index_to_address(gpbf->text, index + len);
		len++;
		if ((*c == LF) && ((gpbf->eol == EOL_UNIX) || (prevc == CR)))
			break;

		prevc = *c;
	}
	*out = len;
	return 1;
}

size_t
gpbf_count_lines(gpbf_t *gpbf)
{
	size_t lines = (size_t)gpbf->line_cache.linum + 1;
	gpbf_index_t index = gpbf->line_cache.index;
	uint8_t prevc = 0;

	for (; index < gpbf_array_num_elements(gpbf->text); index++) {
		uint8_t *c = gpbf_array_index_to_address(gpbf->text, index);
		if ((*c == LF) && ((gpbf->eol == EOL_UNIX) || (prevc == CR)))
			lines ++;
		prevc = *c;
	}
	return lines;
}

int
gpbf_insert(gpbf_t *gpbf, gpbf_index_t index, size_t len, const uint8_t *text)
{
	if (gpbf_array_num_elements(gpbf->text) < index)
		return 0;

	int ret = gpbf_array_insert(gpbf->text, index, len, text);
	if (!ret)
		return 0;

	if (index < gpbf->line_cache.index)
		gpbf_reset_line_cache(gpbf);

	return 1;
}

static int
gpbf_check_index_and_len(const gpbf_t *gpbf, gpbf_index_t index, size_t len)
{
	if (gpbf_array_num_elements(gpbf->text) < index)
		return 0;

	if (gpbf_array_num_elements(gpbf->text) - index < len)
		return 0;

	return 1;
}

int
gpbf_copy_text(gpbf_t *gpbf, gpbf_index_t index, size_t len, uint8_t *out)
{
	if (gpbf_check_index_and_len(gpbf, index, len)) {
		gpbf_array_copy_elements(gpbf->text, index, len, out);
		return 1;
	}
	return 0;
}

size_t
gpbf_length(const gpbf_t *gpbf)
{
	return gpbf_array_num_elements(gpbf->text);
}

int
gpbf_delete(gpbf_t *gpbf, gpbf_index_t index, size_t len)
{
	if (gpbf_check_index_and_len(gpbf, index, len)) {
		gpbf_array_delete(gpbf->text, index, len);
		if (index < gpbf->line_cache.index)
			gpbf_reset_line_cache(gpbf);
		return 1;
	}
	return 0;
}

void
gpbf_clear(gpbf_t *gpbf)
{
	size_t len = gpbf_length(gpbf);
	if (len > 0)
		gpbf_delete(gpbf, 0, len);
}

int
gpbf_adjust_index_forward(const gpbf_t *gpbf, gpbf_index_t index, gpbf_index_t *out)
{
	uint8_t prevc = 0;

	if (index > gpbf_length(gpbf))
		return 0;

	for (; index < gpbf_length(gpbf); index++) {
		uint8_t *c = gpbf_array_index_to_address(gpbf->text, index);
		if (gpbf_utf8_middle_p(*c))
			continue;
		if (gpbf->eol == EOL_UNIX)
			break;
		if ((*c != LF) || (prevc != CR))
			break;
		prevc = *c;
	}
	*out = index;
	return 1;
}

int
gpbf_adjust_index_backward(const gpbf_t *gpbf, gpbf_index_t index, gpbf_index_t *out)
{
	uint8_t prevc = 0;

	if (index > gpbf_length(gpbf))
		return 0;

	if (index == gpbf_length(gpbf)) {
		*out = index;
		return 1;
	}

	for (; index > 0; index--) {
		uint8_t *c = gpbf_array_index_to_address(gpbf->text, index);
		if (gpbf_utf8_middle_p(*c))
			continue;
		if (gpbf->eol == EOL_UNIX)
			break;
		if (*c != LF)
			break;
		c = gpbf_array_index_to_address(gpbf->text, index - 1);
		if (*c != CR)
			break;
	}
	*out = index;
	return 1;
}

#ifdef DEBUG
gpbf_index_t
gpbf_text_gap_begin(gpbf_t *gpbf)
{
	return gpbf->text->gap_begin;
}

size_t
gpbf_text_gap_length(gpbf_t *gpbf)
{
	return gpbf->text->gap_length;
}

size_t
gpbf_alloc_unit()
{
	return ALLOC_UNIT_TEXT;
}

size_t
gpbf_text_capacity(gpbf_t *gpbf)
{
	return gpbf->text->capacity;
}
#endif
