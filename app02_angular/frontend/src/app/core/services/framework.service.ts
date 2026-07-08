import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { Framework } from '../../shared/models/framework.model';

const API_BASE = '/api/v1';

@Injectable({ providedIn: 'root' })
export class FrameworkService {
  private readonly http = inject(HttpClient);

  getFrameworks(): Observable<Framework[]> {
    return this.http.get<Framework[]>(`${API_BASE}/frameworks`);
  }

  getFramework(code: string): Observable<Framework> {
    return this.http.get<Framework>(`${API_BASE}/frameworks/${code}`);
  }
}
