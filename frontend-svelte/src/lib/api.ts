import { browser } from '$app/environment';

const API_BASE_URL = import.meta.env.PUBLIC_API_BASE_URL || '/api/v1';
const ACCESS_TOKEN_KEY = 'ligas.accessToken';
const REFRESH_TOKEN_KEY = 'ligas.refreshToken';

export type PermissionLevel =
  | 'TOTAL'
  | 'LECTURA'
  | 'MODIFICACION'
  | 'LECTURA_CLUB'
  | 'MODIFICACION_CLUB'
  | 'NO';

export const MATRIX_MODULES = [
  'LIGAS',
  'TORNEOS',
  'ZONAS',
  'CATEGORIAS',
  'JUGADORES',
  'CLUBES',
  'CONFIGURACION'
] as const;

export type MatrixModule = (typeof MATRIX_MODULES)[number];

export interface AuthUser {
  id: number;
  username: string;
  firstName: string;
  lastName: string;
  isAdmin: boolean;
  roles: string[];
  permissions: unknown[];
  moduleLevels: Record<string, PermissionLevel>;
  club: { id: number; name: string } | null;
}

export function canViewModule(user: AuthUser | null | undefined, module: string): boolean {
  if (!user) return false;
  if (user.isAdmin) return true;
  const level = user.moduleLevels?.[module] ?? 'NO';
  return level !== 'NO';
}

export function canManageModule(user: AuthUser | null | undefined, module: string): boolean {
  if (!user) return false;
  if (user.isAdmin) return true;
  const level = user.moduleLevels?.[module] ?? 'NO';
  return level === 'TOTAL' || level === 'MODIFICACION';
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

export interface Player {
  id: number;
  firstName: string;
  lastName: string;
  dni: string;
  birthDate: string;
  gender: string;
  active: boolean;
  addressStreet?: string | null;
  addressNumber?: string | null;
  addressCity?: string | null;
  emergencyName?: string | null;
  emergencyRelationship?: string | null;
  emergencyPhone?: string | null;
}

export interface PaginatedPlayers {
  data: Player[];
  total: number;
  page: number;
  pageSize: number;
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
  controlsPlayers?: boolean;
}

export interface Zone {
  id: number;
  name: string;
  tournamentId: number;
  status: string;
  lockedAt?: string | null;
  tournament: { name: string; year: number; league: { name: string } };
  clubZones?: { club: Club }[];
  _count?: { clubZones: number; matches: number };
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
  zone: {
    id: number;
    name: string;
    tournamentId: number;
    tournamentName: string;
    tournamentYear: number;
    leagueId: number;
    leagueName: string;
  };
  general: StandingRow[];
  categories: {
    tournamentCategoryId: number;
    categoryId: number;
    categoryName: string;
    birthYearMin: number;
    birthYearMax: number;
    countsForGeneral: boolean;
    standings: StandingRow[];
  }[];
}

export interface UserRow {
  id: number;
  username: string;
  firstName: string;
  lastName: string;
  isAdmin: boolean;
  club: { id: number; name: string } | null;
  moduleLevels: Record<string, PermissionLevel>;
}

export interface PaginatedUsers {
  data: UserRow[];
  total: number;
  page: number;
  pageSize: number;
}

export interface SiteIdentity {
  title: string;
  iconUrl?: string | null;
  flyerUrl?: string | null;
  paletteId?: string | null;
  favicon?: { basePath: string; updatedAt: number } | null;
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

export async function login(username: string, password: string): Promise<AuthUser> {
  const response = await request<AuthResponse>('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ username, password })
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

export async function uploadClubLogo(clubId: number, file: File): Promise<void> {
  const form = new FormData();
  form.append('logo', file);
  const headers = new Headers();
  const accessToken = getStored(ACCESS_TOKEN_KEY);
  if (accessToken) headers.set('Authorization', `Bearer ${accessToken}`);
  const response = await fetch(`${API_BASE_URL}/clubs/${clubId}/logo`, { method: 'PUT', headers, body: form });
  if (!response.ok) {
    let message = 'No se pudo subir el escudo.';
    try {
      const body = await response.json();
      const msg = body.message;
      message = Array.isArray(msg) ? msg.join(', ') : (typeof msg === 'string' && msg ? msg : message);
    } catch {}
    throw new Error(message);
  }
}

export async function deleteClubLogo(clubId: number): Promise<void> {
  await request(`/clubs/${clubId}/logo`, { method: 'DELETE' });
}

export async function getPlayers(search = '', page = 1): Promise<PaginatedPlayers> {
  const params = new URLSearchParams();
  if (search) params.set('search', search);
  params.set('page', String(page));
  params.set('pageSize', '25');
  return request<PaginatedPlayers>(`/players?${params}`);
}

export async function createPlayer(input: Record<string, unknown>): Promise<Player> {
  return request<Player>('/players', { method: 'POST', body: JSON.stringify(input) });
}

export interface ScanDniResult {
  lastName: string;
  firstName: string;
  sex: 'M' | 'F' | 'X';
  dni: string;
  birthDate: string;
}

export async function scanDni(file: File): Promise<ScanDniResult> {
  const form = new FormData();
  form.append('file', file);
  const headers = new Headers();
  const accessToken = getStored(ACCESS_TOKEN_KEY);
  if (accessToken) headers.set('Authorization', `Bearer ${accessToken}`);
  const response = await fetch(`${API_BASE_URL}/players/dni/scan`, { method: 'POST', headers, body: form });
  if (!response.ok) {
    let message = 'No se pudo escanear el DNI.';
    try {
      const body = await response.json();
      const msg = body.message;
      message = Array.isArray(msg) ? msg.join(', ') : (typeof msg === 'string' && msg ? msg : message);
    } catch {}
    throw new Error(message);
  }
  return response.json();
}

export async function updatePlayer(id: number, input: Record<string, unknown>): Promise<Player> {
  return request<Player>(`/players/${id}`, { method: 'PATCH', body: JSON.stringify(input) });
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

export async function updateTournamentStatus(id: number, status: string): Promise<Tournament> {
  return request<Tournament>(`/tournaments/${id}/status`, { method: 'PUT', body: JSON.stringify({ status }) });
}

export async function deleteTournament(id: number, username: string, password: string): Promise<void> {
  return request(`/tournaments/${id}`, { method: 'DELETE', body: JSON.stringify({ username, password }) });
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

export async function generateFixture(zoneId: number, doubleRound: boolean): Promise<unknown> {
  return request(`/zones/${zoneId}/fixture`, { method: 'POST', body: JSON.stringify({ doubleRound }) });
}

export async function previewFixture(zoneId: number, doubleRound: boolean): Promise<unknown> {
  return request(`/zones/${zoneId}/fixture/preview`, { method: 'POST', body: JSON.stringify({ doubleRound }) });
}

export async function finalizeZone(zoneId: number): Promise<unknown> {
  return request(`/zones/${zoneId}/finalize`, { method: 'POST' });
}

export async function createZone(tournamentId: number, name: string): Promise<Zone> {
  return request<Zone>(`/tournaments/${tournamentId}/zones`, { method: 'POST', body: JSON.stringify({ name }) });
}

export async function deleteZone(zoneId: number): Promise<void> {
  return request(`/zones/${zoneId}`, { method: 'DELETE' });
}

export async function generateManualFixture(zoneId: number, data: { matchdays: { matchday: number; round: string; matches: { homeClubId: number; awayClubId: number }[]; byeClubId?: number }[]; doubleRound?: boolean }): Promise<unknown> {
  return request(`/zones/${zoneId}/fixture/manual`, { method: 'POST', body: JSON.stringify(data) });
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

export interface ZoneMatchCategory {
  id: number;
  tournamentCategoryId: number;
  kickoffTime: string | null;
  isPromocional: boolean;
  homeScore: number;
  awayScore: number;
  closedAt: string | null;
  isPending: boolean;
  tournamentCategory: { category: { id: number; name: string } };
}

export interface ZoneMatch {
  id: number;
  matchday: number;
  round: string;
  date: string | null;
  status: string;
  homeClubId: number | null;
  awayClubId: number | null;
  homeClub: { id: number; name: string } | null;
  awayClub: { id: number; name: string } | null;
  categories: ZoneMatchCategory[];
  pointsHome: number;
  pointsAway: number;
}

export interface ZoneMatchday {
  id: number;
  zoneId: number;
  matchday: number;
  status: string;
  date: string | null;
}

export interface ZoneMatchesResponse {
  matches: ZoneMatch[];
  matchdays: ZoneMatchday[];
}

export interface TournamentZoneClub {
  id: number;
  name: string;
  shortName?: string | null;
  eligible: boolean;
  categories: { tournamentCategoryId: number; categoryId: number; categoryName: string; mandatory: boolean; minPlayers: number; hasTeam: boolean; playersCount: number; meetsMinPlayers: boolean }[];
}

export interface TournamentZone {
  id: number;
  name: string;
  clubs: { id: number; clubId: number; clubName: string }[];
}

export async function getZoneMatches(zoneId: number): Promise<ZoneMatchesResponse> {
  return request<ZoneMatchesResponse>(`/zones/${zoneId}/matches`);
}

export interface MatchClub {
  id: number;
  name: string;
  shortName: string | null;
  logoUrl: string | null;
  primaryColor: string | null;
  secondaryColor: string | null;
}

export interface MatchDetail {
  id: number;
  matchday: number;
  round: string;
  status: string;
  date: string | null;
  zone: { id: number; name: string };
  homeClub: MatchClub | null;
  awayClub: MatchClub | null;
  categories: {
    tournamentCategoryId: number;
    categoryName: string;
    isPromocional: boolean;
    countsForGeneral: boolean;
    kickoffTime: string | null;
    homeScore: number;
    awayScore: number;
    closedAt: string | null;
    isPending: boolean;
  }[];
  tournament: {
    id: number;
    pointsWin: number;
    pointsDraw: number;
    pointsLoss: number;
    controlsPlayers: boolean;
  };
  pointsHome: number;
  pointsAway: number;
}

export async function getMatchDetail(matchId: number): Promise<MatchDetail> {
  return request<MatchDetail>(`/matches/${matchId}`);
}

export interface MatchCategoryResult {
  matchId: number;
  tournamentCategoryId: number;
  homeClubId: number | null;
  awayClubId: number | null;
  homeScore: number;
  awayScore: number;
  isPending: boolean;
  closedAt: string | null;
  playerGoals: { playerId: number; clubId: number; goals: number; player: { id: number; firstName: string | null; lastName: string | null } }[];
  otherGoals: { clubId: number; goals: number }[];
}

export async function getMatchCategoryResult(matchId: number, tournamentCategoryId: number): Promise<MatchCategoryResult> {
  return request<MatchCategoryResult>(`/matches/${matchId}/categories/${tournamentCategoryId}/result`);
}

export interface AssignedPlayerRow {
  id: number;
  firstName: string;
  lastName: string;
  birthDate: string;
  gender: string;
}

export async function listAssignedPlayers(clubId: number, tournamentCategoryId: number): Promise<AssignedPlayerRow[]> {
  const data = await request<{ players: AssignedPlayerRow[] }>(
    `/clubs/${clubId}/tournament-categories/${tournamentCategoryId}/assigned-players?page=1&pageSize=200`
  );
  return data.players;
}

export async function recordMatchResult(
  matchId: number,
  tournamentCategoryId: number,
  data: {
    homeScore: number;
    awayScore: number;
    confirm: boolean;
    pending?: boolean;
    playerGoals: { playerId: number; clubId: number; goals: number }[];
    otherGoals: { clubId: number; goals: number }[];
  }
): Promise<unknown> {
  return request(`/matches/${matchId}/categories/${tournamentCategoryId}/result`, { method: 'POST', body: JSON.stringify(data) });
}

export async function finalizeMatchday(zoneId: number, matchday: number): Promise<unknown> {
  return request(`/zones/${zoneId}/matchdays/${matchday}/finalize`, { method: 'POST' });
}

export async function updateMatchday(zoneId: number, matchday: number, date: string | null): Promise<unknown> {
  return request(`/zones/${zoneId}/matchdays/${matchday}`, { method: 'PATCH', body: JSON.stringify({ date }) });
}

export async function getTournamentZones(tournamentId: number): Promise<TournamentZone[]> {
  return request<TournamentZone[]>(`/tournaments/${tournamentId}/zones`);
}

export async function getZoneClubs(zoneId: number): Promise<TournamentZoneClub[]> {
  return request<TournamentZoneClub[]>(`/zones/${zoneId}/clubs`);
}

export async function getTournamentZoneClubs(tournamentId: number, zoneId?: number): Promise<TournamentZoneClub[]> {
  const params = zoneId ? `?zoneId=${zoneId}` : '';
  return request<TournamentZoneClub[]>(`/tournaments/${tournamentId}/zones/clubs${params}`);
}

export interface AssignedPlayer {
  id: number;
  playerId: number;
  playerName: string;
  playerDni: string;
  playerBirthDate: string;
  clubId: number;
  clubName: string;
  tournamentCategoryId: number;
  categoryName: string;
  jersey?: number | null;
}

export async function getAssignedPlayers(tournamentId: number, clubId: number): Promise<AssignedPlayer[]> {
  return request<AssignedPlayer[]>(`/tournaments/${tournamentId}/player-club?clubId=${clubId}`);
}

export async function assignPlayerToClub(tournamentId: number, data: { playerId: number; clubId: number; tournamentCategoryId: number; jersey?: number }): Promise<void> {
  return request(`/tournaments/${tournamentId}/player-club`, { method: 'PUT', body: JSON.stringify(data) });
}

export async function removePlayerFromClub(tournamentId: number, clubId: number, playerId: number): Promise<void> {
  return request(`/tournaments/${tournamentId}/player-club`, { method: 'DELETE', body: JSON.stringify({ playerId, clubId }) });
}

export async function searchPlayersByDni(dni: string): Promise<Player[]> {
  return request<Player[]>(`/players/search?dni=${dni}`);
}

export interface AvailableTournament {
  id: number;
  name: string;
  year: number;
  leagueId: number;
  leagueName: string;
  categories: {
    tournamentCategoryId: number;
    categoryId: number;
    categoryName: string;
    birthYearMin: number;
    birthYearMax: number;
    gender: string;
    minPlayers: number;
    mandatory: boolean;
  }[];
}

export async function getAvailableTournaments(clubId: number): Promise<AvailableTournament[]> {
  return request<AvailableTournament[]>(`/clubs/${clubId}/available-tournaments`);
}

export async function joinTournament(clubId: number, data: { tournamentId: number; tournamentCategoryIds: number[] }): Promise<void> {
  return request(`/clubs/${clubId}/available-tournaments`, { method: 'POST', body: JSON.stringify(data) });
}

export async function getUsers(search?: string, page?: number): Promise<PaginatedUsers> {
  const params = new URLSearchParams();
  if (search) params.set('search', search);
  if (page) params.set('page', String(page));
  return request<PaginatedUsers>(`/users${params.toString() ? `?${params}` : ''}`);
}

export interface CreateUserInput {
  username: string;
  password: string;
  firstName: string;
  lastName: string;
  clubId?: number | null;
  permissions: { module: MatrixModule; level: PermissionLevel }[];
}

export async function createUser(input: CreateUserInput): Promise<UserRow> {
  return request<UserRow>('/users', { method: 'POST', body: JSON.stringify(input) });
}

export async function updateUser(id: number, input: { firstName?: string; lastName?: string; clubId?: number | null }): Promise<UserRow> {
  return request<UserRow>(`/users/${id}`, { method: 'PATCH', body: JSON.stringify(input) });
}

export async function setUserPermissions(id: number, permissions: { module: MatrixModule; level: PermissionLevel }[]): Promise<UserRow> {
  return request<UserRow>(`/users/${id}/permissions`, { method: 'PUT', body: JSON.stringify({ permissions }) });
}

export async function setUserPassword(id: number, password: string): Promise<void> {
  return request(`/users/${id}/password`, { method: 'POST', body: JSON.stringify({ password }) });
}

export async function deleteUser(id: number): Promise<void> {
  return request(`/users/${id}`, { method: 'DELETE' });
}

export async function listAllClubs(): Promise<Club[]> {
  const params = new URLSearchParams();
  params.set('page', '1');
  params.set('pageSize', '200');
  const data = await request<PaginatedClubs>(`/clubs?${params}`);
  return data.data;
}

export async function getLeaderboards(tournamentId: number, zoneId?: number, categoryId?: number): Promise<unknown> {
  const params = new URLSearchParams();
  params.set('tournamentId', String(tournamentId));
  if (zoneId) params.set('zoneId', String(zoneId));
  if (categoryId) params.set('categoryId', String(categoryId));
  return request(`/stats/leaderboards?${params}`);
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

export interface ClubAdminTournament {
  id: number; name: string; year: number; leagueName: string;
  categories: { id: number; category: { id: number; name: string }; kickoffTime?: string|null; countsForGeneral: boolean }[];
  zone?: { id: number; name: string }|null;
}

export interface ClubAdminOverview {
  club: { id: number; name: string; shortName?: string|null; slug: string; logoUrl?: string|null; primaryColor?: string|null; secondaryColor?: string|null; instagramUrl?: string|null; facebookUrl?: string|null; homeAddress?: string|null; latitude?: number|null; longitude?: number|null; active: boolean };
  tournaments: ClubAdminTournament[];
}

export interface RosterPlayer {
  id: number; playerId: number; jersey?: number|null;
  player: { id: number; firstName: string; lastName: string; dni: string };
}

export interface RosterCategory {
  id: number; clubId: number; tournamentCategoryId: number; lockedAt?: string|null;
  tournamentCategory: { tournament: { id: number; name: string }; category: { id: number; name: string } };
  players: RosterPlayer[];
}

export async function getClubAdmin(slug: string): Promise<ClubAdminOverview> {
  return request<ClubAdminOverview>(`/clubs/${slug}/admin`);
}

export async function leaveTournament(clubId: number, tournamentId: number): Promise<void> {
  return request(`/clubs/${clubId}/tournaments/${tournamentId}`, { method: 'DELETE' });
}

export async function getClubRoster(clubId: number): Promise<{ tournamentCategories: RosterCategory[] }> {
  return request(`/clubs/${clubId}/roster`);
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
