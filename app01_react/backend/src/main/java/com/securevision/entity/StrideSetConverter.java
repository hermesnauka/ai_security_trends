package com.securevision.entity;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.stream.Collectors;

@Converter
public class StrideSetConverter implements AttributeConverter<Set<StrideCategory>, String> {

    @Override
    public String convertToDatabaseColumn(Set<StrideCategory> attribute) {
        if (attribute == null || attribute.isEmpty()) {
            return null;
        }
        return attribute.stream().map(Enum::name).collect(Collectors.joining(","));
    }

    @Override
    public Set<StrideCategory> convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.isBlank()) {
            return Set.of();
        }
        return Arrays.stream(dbData.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(StrideCategory::valueOf)
                .collect(Collectors.toCollection(LinkedHashSet::new));
    }
}
