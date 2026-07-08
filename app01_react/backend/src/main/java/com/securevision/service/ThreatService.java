package com.securevision.service;

import com.securevision.dto.ThreatResponse;
import com.securevision.dto.ThreatSummaryResponse;
import com.securevision.entity.Severity;
import com.securevision.entity.Threat;
import com.securevision.exception.ResourceNotFoundException;
import com.securevision.repository.ThreatRepository;
import com.securevision.repository.ThreatSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ThreatService {

    private final ThreatRepository threatRepository;

    public Page<ThreatSummaryResponse> search(
            String frameworkCode, String severity, String stride, String tag, String q, Pageable pageable) {

        Severity severityEnum = StringUtils.hasText(severity) ? Severity.valueOf(severity.toUpperCase()) : null;

        Specification<Threat> spec = Specification
                .where(ThreatSpecifications.hasFrameworkCode(frameworkCode))
                .and(ThreatSpecifications.hasSeverity(severityEnum))
                .and(ThreatSpecifications.hasStride(stride))
                .and(ThreatSpecifications.hasTag(tag))
                .and(ThreatSpecifications.textSearch(q));

        return threatRepository.findAll(spec, pageable).map(ThreatSummaryResponse::from);
    }

    public ThreatResponse getById(UUID id) {
        return threatRepository.findById(id)
                .map(ThreatResponse::from)
                .orElseThrow(() -> new ResourceNotFoundException("Threat not found: " + id));
    }
}
