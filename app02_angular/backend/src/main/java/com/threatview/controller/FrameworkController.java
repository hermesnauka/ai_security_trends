package com.threatview.controller;

import com.threatview.dto.FrameworkResponse;
import com.threatview.service.FrameworkService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/frameworks")
@RequiredArgsConstructor
@Tag(name = "Frameworks")
public class FrameworkController {

    private final FrameworkService frameworkService;

    @GetMapping
    @Operation(summary = "List all security frameworks catalogued in ThreatView")
    public List<FrameworkResponse> getAll() {
        return frameworkService.getAll();
    }

    @GetMapping("/{code}")
    @Operation(summary = "Get a single framework by its code, e.g. OWASP_LLM")
    public FrameworkResponse getByCode(@PathVariable String code) {
        return frameworkService.getByCode(code);
    }
}
