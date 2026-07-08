package com.threatview.repository;

import com.threatview.entity.Threat;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.UUID;

public interface ThreatRepository extends JpaRepository<Threat, UUID>, JpaSpecificationExecutor<Threat> {
}
