package com.securevision.dto;

import com.securevision.entity.Framework;
import lombok.Builder;

@Builder
public record FrameworkResponse(
        String id,
        String code,
        String name,
        String version,
        String description,
        String referenceUrl
) {
    public static FrameworkResponse from(Framework framework) {
        return FrameworkResponse.builder()
                .id(framework.getId().toString())
                .code(framework.getCode())
                .name(framework.getName())
                .version(framework.getVersion())
                .description(framework.getDescription())
                .referenceUrl(framework.getReferenceUrl())
                .build();
    }
}
