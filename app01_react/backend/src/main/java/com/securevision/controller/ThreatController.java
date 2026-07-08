package com.securevision.controller;

import com.securevision.dto.ThreatResponse;
import com.securevision.dto.ThreatSummaryResponse;
import com.securevision.service.ThreatService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/threats")
@RequiredArgsConstructor
@Tag(name = "Threats")
public class ThreatController {

    private final ThreatService threatService;

    @GetMapping
    @Operation(summary = "List threats with optional filters and pagination")
    public Page<ThreatSummaryResponse> search(
            @RequestParam(required = false) String frameworkCode,
            @RequestParam(required = false) String severity,
            @RequestParam(required = false) String stride,
            @RequestParam(required = false) String tag,
            @RequestParam(required = false) String q,
            Pageable pageable) {
        return threatService.search(frameworkCode, severity, stride, tag, q, pageable);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get full detail for a single threat")
    public ThreatResponse getById(@PathVariable UUID id) {
        return threatService.getById(id);
    }
}
