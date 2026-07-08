package com.securevision.service;

import com.securevision.dto.FrameworkResponse;
import com.securevision.exception.ResourceNotFoundException;
import com.securevision.repository.FrameworkRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FrameworkService {

    private final FrameworkRepository frameworkRepository;

    public List<FrameworkResponse> getAll() {
        return frameworkRepository.findAll().stream()
                .map(FrameworkResponse::from)
                .toList();
    }

    public FrameworkResponse getByCode(String code) {
        return frameworkRepository.findByCode(code)
                .map(FrameworkResponse::from)
                .orElseThrow(() -> new ResourceNotFoundException("Framework not found: " + code));
    }
}
