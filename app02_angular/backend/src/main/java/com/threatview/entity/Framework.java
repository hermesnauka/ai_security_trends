package com.threatview.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.UUID;

@Entity
@Table(name = "framework")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Framework {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false, unique = true, length = 64)
    private String code;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false, length = 32)
    private String version;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "reference_url", length = 512)
    private String referenceUrl;
}
