import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { Page, ThreatDetail, ThreatSummary } from '../../shared/models/threat.model';

const API_BASE = '/api/v1';

export interface ThreatSearchParams {
  frameworkCode?: string;
  severity?: string;
  q?: string;
  page?: number;
  size?: number;
}

@Injectable({ providedIn: 'root' })
export class ThreatService {
  private readonly http = inject(HttpClient);

  search(params: ThreatSearchParams = {}): Observable<Page<ThreatSummary>> {
    let httpParams = new HttpParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined && value !== '') {
        httpParams = httpParams.set(key, String(value));
      }
    });
    return this.http.get<Page<ThreatSummary>>(`${API_BASE}/threats`, { params: httpParams });
  }

  getById(id: string): Observable<ThreatDetail> {
    return this.http.get<ThreatDetail>(`${API_BASE}/threats/${id}`);
  }
}
