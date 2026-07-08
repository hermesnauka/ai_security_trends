package com.threatview.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "threat")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Threat {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "framework_id", nullable = false)
    private Framework framework;

    @Column(nullable = false, length = 64)
    private String code;

    @Column(nullable = false)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Severity severity;

    @Column(length = 128)
    private String category;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "attack_vector", columnDefinition = "TEXT")
    private String attackVector;

    @Column(name = "attack_surface", columnDefinition = "TEXT")
    private String attackSurface;

    @Convert(converter = StrideSetConverter.class)
    @Column(length = 32)
    private Set<StrideCategory> stride;

    @Convert(converter = StringListConverter.class)
    @Column(name = "cve_references", columnDefinition = "TEXT")
    private List<String> cveReferences;

    @Convert(converter = StringListConverter.class)
    @Column(columnDefinition = "TEXT")
    private List<String> tags;
}
