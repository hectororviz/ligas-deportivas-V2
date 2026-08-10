import { browser } from '$app/environment';

const API_BASE_URL = import.meta.env.PUBLIC_API_BASE_URL || '/api/v1';
const ACCESS_TOKEN_KEY = 'ligas.accessToken';
const REFRESH_TOKEN_KEY = 'ligas.refreshToken';

export interface AuthUser {
  id: number;
  email: string;
  firstName: string;
  lastName: string;
  roles: string[];
  permissions: unknown[];
  club: { id: number; name: string } | null;
}

export interface HomeStanding {
  clubId: number;
  clubName: string;
  points: number;
  goalsFor: number;
  goalsAgainst: number;
  goalDifference: number;
}

export interface HomeMatchday {
  matchday: number;
  date: string | null;
  status: string;
  kickoffTime: string | null;
}

export interface HomeZone {
  id: number;
  name: string;
  top: HomeStanding[];
  nextMatchday: HomeMatchday | null;
}

export interface HomeTournament {
  id: number;
  leagueName: string;
  name: string;
  year: number;
  zones: HomeZone[];
}

export interface HomeSummary {
  generatedAt: string;
  tournaments: HomeTournament[];
}

export interface League {
  id: number;
  name: string;
  slug: string;
  colorHex: string;
  gameDay: string;
}

interface AuthResponse {
  user: AuthUser;
  accessToken: string;
  refreshToken: string;
}

function getStored(key: string): string | null {
  return browser ? localStorage.getItem(key) : null;
}

function storeAuth(response: AuthResponse) {
  if (!browser) return;
  localStorage.setItem(ACCESS_TOKEN_KEY, response.accessToken);
  localStorage.setItem(REFRESH_TOKEN_KEY, response.refreshToken);
}

export function clearAuth() {
  if (!browser) return;
  localStorage.removeItem(ACCESS_TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
}

async function request<T>(path: string, init: RequestInit = {}, retry = true): Promise<T> {
  const headers = new Headers(init.headers);
  headers.set('Content-Type', 'application/json');

  const accessToken = getStored(ACCESS_TOKEN_KEY);
  if (accessToken) headers.set('Authorization', `Bearer ${accessToken}`);

  const response = await fetch(`${API_BASE_URL}${path}`, { ...init, headers });

  if (response.status === 401 && retry && getStored(REFRESH_TOKEN_KEY)) {
    try {
      const refreshed = await request<AuthResponse>('/auth/refresh', {
        method: 'POST',
        body: JSON.stringify({ refreshToken: getStored(REFRESH_TOKEN_KEY) })
      }, false);
      storeAuth(refreshed);
      return request<T>(path, init, false);
    } catch {
      clearAuth();
    }
  }

  if (!response.ok) {
    let message = 'No se pudo completar la solicitud.';
    try {
      const body = await response.json();
      message = Array.isArray(body.message) ? body.message.join(', ') : body.message || message;
    } catch {
      // Keep a safe generic message when the API response is not JSON.
    }
    throw new Error(message);
  }

  return response.json() as Promise<T>;
}

export async function login(email: string, password: string): Promise<AuthUser> {
  const response = await request<AuthResponse>('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password })
  }, false);
  storeAuth(response);
  return response.user;
}

export async function getProfile(): Promise<AuthUser> {
  return request<AuthUser>('/auth/profile');
}

export async function getHomeSummary(): Promise<HomeSummary> {
  return request<HomeSummary>('/home/summary');
}

export async function getLeagues(): Promise<League[]> {
  return request<League[]>('/leagues');
}

export async function createLeague(input: Omit<League, 'id'>): Promise<League> {
  return request<League>('/leagues', {
    method: 'POST',
    body: JSON.stringify(input)
  });
}

export async function updateLeague(id: number, input: Partial<Omit<League, 'id'>>): Promise<League> {
  return request<League>(`/leagues/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(input)
  });
}

export async function logout(): Promise<void> {
  const refreshToken = getStored(REFRESH_TOKEN_KEY);
  if (refreshToken) {
    await request('/auth/logout', {
      method: 'POST',
      body: JSON.stringify({ refreshToken })
    }, false).catch(() => undefined);
  }
  clearAuth();
}

export function hasSession(): boolean {
  return Boolean(getStored(ACCESS_TOKEN_KEY) || getStored(REFRESH_TOKEN_KEY));
}
