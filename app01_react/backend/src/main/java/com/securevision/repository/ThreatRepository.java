package com.securevision.repository;

import com.securevision.entity.Threat;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.UUID;

public interface ThreatRepository extends JpaRepository<Threat, UUID>, JpaSpecificationExecutor<Threat> {
}
