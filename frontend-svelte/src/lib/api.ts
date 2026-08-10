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

export interface Club {
  id: number;
  name: string;
  active: boolean;
  slug?: string | null;
  shortName?: string | null;
  primaryColor?: string | null;
  secondaryColor?: string | null;
  instagramUrl?: string | null;
  facebookUrl?: string | null;
  homeAddress?: string | null;
  latitude?: string | number | null;
  longitude?: string | number | null;
  logoUrl?: string | null;
  league?: { name: string } | null;
}

export interface Category {
  id: number;
  name: string;
  birthYearMin: number;
  birthYearMax: number;
  gender: string;
  minPlayers: number;
  mandatory: boolean;
  promotional: boolean;
  active: boolean;
}

export interface Tournament {
  id: number;
  name: string;
  year: number;
  gender: string;
  status: string;
  championMode: string;
  pointsWin: number;
  pointsDraw: number;
  pointsLoss: number;
  startDate?: string | null;
  endDate?: string | null;
  leagueId: number;
  league: { name: string };
}

export interface Zone {
  id: number;
  name: string;
  tournamentId: number;
  status: string;
  lockedAt?: string | null;
  tournament: { name: string; year: number; league: { name: string } };
  clubZones?: { club: Club }[];
}

export interface StandingRow {
  clubId: number;
  clubName: string;
  played: number;
  wins: number;
  draws: number;
  losses: number;
  goalsFor: number;
  goalsAgainst: number;
  goalDifference: number;
  points: number;
}

export interface ZoneStanding {
  zoneId: number;
  zoneName: string;
  tournamentName: string;
  categories: { categoryId: number; categoryName: string; standings: StandingRow[] }[];
}

export interface SiteIdentity {
  title: string;
  iconKey?: string | null;
  flyerKey?: string | null;
  backgroundImage?: string | null;
  layoutSvg?: string | null;
  faviconHash?: string | null;
  iconUrl?: string;
  flyerUrl?: string;
}

export interface PaginatedClubs {
  data: Club[];
  total: number;
  page: number;
  pageSize: number;
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

export async function getClubs(search = '', status = '', page = 1): Promise<PaginatedClubs> {
  const params = new URLSearchParams();
  if (search) params.set('search', search);
  if (status) params.set('status', status);
  params.set('page', String(page));
  params.set('pageSize', '25');
  return request<PaginatedClubs>(`/clubs?${params}`);
}

export async function createClub(input: Record<string, unknown>): Promise<Club> {
  return request<Club>('/clubs', {
    method: 'POST',
    body: JSON.stringify(input)
  });
}

export async function updateClub(id: number, input: Record<string, unknown>): Promise<Club> {
  return request<Club>(`/clubs/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(input)
  });
}

export async function getCategories(): Promise<Category[]> {
  return request<Category[]>('/categories');
}

export async function createCategory(input: Record<string, unknown>): Promise<Category> {
  return request<Category>('/categories', { method: 'POST', body: JSON.stringify(input) });
}

export async function updateCategory(id: number, input: Record<string, unknown>): Promise<Category> {
  return request<Category>(`/categories/${id}`, { method: 'PATCH', body: JSON.stringify(input) });
}

export async function getTournaments(includeInactive = false): Promise<Tournament[]> {
  return request<Tournament[]>(`/tournaments${includeInactive ? '?includeInactive=true' : ''}`);
}

export async function createTournament(input: Record<string, unknown>): Promise<Tournament> {
  return request<Tournament>('/tournaments', { method: 'POST', body: JSON.stringify(input) });
}

export async function updateTournament(id: number, input: Record<string, unknown>): Promise<Tournament> {
  return request<Tournament>(`/tournaments/${id}`, { method: 'PUT', body: JSON.stringify(input) });
}

export async function getZones(includeInactive = false): Promise<Zone[]> {
  return request<Zone[]>(`/zones${includeInactive ? '?includeInactive=true' : ''}`);
}

export async function assignClubToZone(zoneId: number, clubId: number): Promise<void> {
  return request(`/zones/${zoneId}/clubs`, { method: 'POST', body: JSON.stringify({ clubId }) });
}

export async function removeClubFromZone(zoneId: number, clubId: number): Promise<void> {
  return request(`/zones/${zoneId}/clubs/${clubId}`, { method: 'DELETE' });
}

export async function generateFixture(zoneId: number, idaVuelta: boolean): Promise<unknown> {
  return request(`/zones/${zoneId}/fixture`, { method: 'POST', body: JSON.stringify({ idaVuelta }) });
}

export async function generateTournamentFixture(tournamentId: number, idaVuelta: boolean): Promise<unknown> {
  return request(`/tournaments/${tournamentId}/fixtures/generate`, { method: 'POST', body: JSON.stringify({ idaVuelta }) });
}

export async function getZoneStandings(zoneId: number): Promise<ZoneStanding> {
  return request<ZoneStanding>(`/zones/${zoneId}/standings`);
}

export async function getTournamentStandings(tournamentId: number): Promise<unknown> {
  return request(`/tournaments/${tournamentId}/standings`);
}

export async function getSiteIdentity(): Promise<SiteIdentity> {
  return request<SiteIdentity>('/site-identity');
}

export async function updateProfile(input: Record<string, unknown>): Promise<AuthUser> {
  return request<AuthUser>('/me', { method: 'PUT', body: JSON.stringify(input) });
}

export async function changePassword(input: { currentPassword: string; newPassword: string }): Promise<void> {
  return request('/me/password', { method: 'POST', body: JSON.stringify(input) });
}

export async function updateSiteIdentity(input: FormData): Promise<SiteIdentity> {
  const headers = new Headers();
  const accessToken = getStored(ACCESS_TOKEN_KEY);
  if (accessToken) headers.set('Authorization', `Bearer ${accessToken}`);
  const response = await fetch(`${API_BASE_URL}/site-identity`, { method: 'PUT', headers, body: input });
  if (!response.ok) throw new Error('No se pudo actualizar la identidad del sitio.');
  return response.json();
}

export async function uploadFavicon(file: File): Promise<void> {
  const form = new FormData();
  form.append('file', file);
  const headers = new Headers();
  const accessToken = getStored(ACCESS_TOKEN_KEY);
  if (accessToken) headers.set('Authorization', `Bearer ${accessToken}`);
  const response = await fetch(`${API_BASE_URL}/site-identity/favicon`, { method: 'POST', headers, body: form });
  if (!response.ok) throw new Error('No se pudo subir el favicon.');
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
