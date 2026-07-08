package com.threatview.dto;

import com.threatview.entity.Threat;
import lombok.Builder;

import java.util.List;
import java.util.Set;

@Builder
public record ThreatSummaryResponse(
        String id,
        String frameworkCode,
        String code,
        String title,
        String severity,
        String category,
        Set<String> stride,
        List<String> tags
) {
    public static ThreatSummaryResponse from(Threat threat) {
        return ThreatSummaryResponse.builder()
                .id(threat.getId().toString())
                .frameworkCode(threat.getFramework().getCode())
                .code(threat.getCode())
                .title(threat.getTitle())
                .severity(threat.getSeverity().name())
                .category(threat.getCategory())
                .stride(threat.getStride() == null ? Set.of() :
                        threat.getStride().stream().map(Enum::name).collect(java.util.stream.Collectors.toSet()))
                .tags(threat.getTags())
                .build();
    }
}
