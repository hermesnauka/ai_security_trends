package com.threatview.dto;

import com.threatview.entity.Threat;
import lombok.Builder;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Full detail view for GET /api/v1/threats/{id}. Nested mitigations and code
 * samples land in Phase 2 (data model 4.5/4.6 are already migrated, just not
 * JPA-mapped yet) - this DTO intentionally omits them rather than fake empty
 * placeholders that would look like "no mitigations exist yet".
 */
@Builder
public record ThreatResponse(
        String id,
        String frameworkCode,
        String frameworkName,
        String code,
        String title,
        String severity,
        String category,
        String description,
        String attackVector,
        String attackSurface,
        Set<String> stride,
        List<String> cveReferences,
        List<String> tags
) {
    public static ThreatResponse from(Threat threat) {
        return ThreatResponse.builder()
                .id(threat.getId().toString())
                .frameworkCode(threat.getFramework().getCode())
                .frameworkName(threat.getFramework().getName())
                .code(threat.getCode())
                .title(threat.getTitle())
                .severity(threat.getSeverity().name())
                .category(threat.getCategory())
                .description(threat.getDescription())
                .attackVector(threat.getAttackVector())
                .attackSurface(threat.getAttackSurface())
                .stride(threat.getStride() == null ? Set.of() :
                        threat.getStride().stream().map(Enum::name).collect(Collectors.toSet()))
                .cveReferences(threat.getCveReferences())
                .tags(threat.getTags())
                .build();
    }
}
