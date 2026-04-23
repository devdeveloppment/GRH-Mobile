package com.grhmobile.dto.common;

import java.util.List;

public record PagedResponse<T>(
    List<T> items,
    long totalItems,
    int page,
    int limit
) {
}
