-- Asmat's World GK Quiz - final online schema
-- Daily reset uses Pakistan Standard Time (Asia/Karachi).

create extension if not exists pgcrypto;

create or replace function public.app_today()
returns date
language sql
stable
as $$
  select (timezone('Asia/Karachi', now()))::date;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null default 'Player' check (char_length(username) between 2 and 24),
  role text not null default 'user' check (role in ('user','admin')),
  total_points integer not null default 0 check (total_points >= 0),
  hint_balance integer not null default 0 check (hint_balance >= 0),
  quizzes_completed integer not null default 0 check (quizzes_completed >= 0),
  total_correct integer not null default 0 check (total_correct >= 0),
  total_wrong integer not null default 0 check (total_wrong >= 0),
  best_score integer not null default 0 check (best_score between 0 and 60),
  is_banned boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.daily_quizzes (
  quiz_date date primary key,
  status text not null default 'generating' check (status in ('generating','published','failed')),
  generated_by text not null default 'gemini',
  created_at timestamptz not null default now(),
  published_at timestamptz
);

create table if not exists public.questions (
  id bigint generated always as identity primary key,
  quiz_date date not null references public.daily_quizzes(quiz_date) on delete cascade,
  position smallint not null check (position between 1 and 60),
  question_text text not null check (char_length(question_text) between 8 and 500),
  options jsonb not null,
  correct_index smallint not null check (correct_index between 0 and 3),
  hint text not null check (char_length(hint) between 3 and 300),
  question_hash text not null,
  created_at timestamptz not null default now(),
  unique (quiz_date, position),
  constraint four_options check (jsonb_typeof(options) = 'array' and jsonb_array_length(options) = 4)
);

create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  quiz_date date not null references public.daily_quizzes(quiz_date) on delete cascade,
  status text not null default 'active' check (status in ('active','completed')),
  current_position smallint not null default 1 check (current_position between 1 and 61),
  correct_count smallint not null default 0 check (correct_count between 0 and 60),
  wrong_count smallint not null default 0 check (wrong_count between 0 and 60),
  points_earned integer not null default 0 check (points_earned between 0 and 600),
  rapid_answer_count smallint not null default 0 check (rapid_answer_count between 0 and 60),
  last_answer_at timestamptz,
  flagged boolean not null default false,
  flag_reason text,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (user_id, quiz_date)
);

create table if not exists public.answers (
  attempt_id uuid not null references public.quiz_attempts(id) on delete cascade,
  question_id bigint not null references public.questions(id) on delete cascade,
  selected_index smallint not null check (selected_index between 0 and 3),
  is_correct boolean not null,
  answered_at timestamptz not null default now(),
  primary key (attempt_id, question_id)
);

create table if not exists public.hint_uses (
  attempt_id uuid not null references public.quiz_attempts(id) on delete cascade,
  question_id bigint not null references public.questions(id) on delete cascade,
  used_at timestamptz not null default now(),
  primary key (attempt_id, question_id)
);

create table if not exists public.check_ins (
  user_id uuid not null references public.profiles(id) on delete cascade,
  check_in_date date not null,
  created_at timestamptz not null default now(),
  primary key (user_id, check_in_date)
);

create table if not exists public.rewarded_hint_claims (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  claimed_at timestamptz not null default now(),
  provider text not null default 'admob'
);

create index if not exists quiz_attempts_date_idx on public.quiz_attempts(quiz_date, points_earned desc);
create index if not exists quiz_attempts_user_idx on public.quiz_attempts(user_id, quiz_date desc);
create index if not exists questions_date_idx on public.questions(quiz_date, position);
create index if not exists questions_hash_idx on public.questions(question_hash);
create index if not exists check_ins_user_idx on public.check_ins(user_id, check_in_date desc);
create index if not exists reward_claims_user_idx on public.rewarded_hint_claims(user_id, claimed_at desc);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_username text;
begin
  v_username := trim(coalesce(new.raw_user_meta_data->>'username', split_part(coalesce(new.email, 'Player'), '@', 1), 'Player'));
  if char_length(v_username) < 2 then v_username := 'Player'; end if;
  if char_length(v_username) > 24 then v_username := left(v_username, 24); end if;
  insert into public.profiles(id, username) values (new.id, v_username)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin' and not is_banned);
$$;

create or replace function public.assert_active_user()
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'NOT_AUTHENTICATED'; end if;
  if not exists(select 1 from public.profiles where id = auth.uid()) then raise exception 'PROFILE_NOT_FOUND'; end if;
  if exists(select 1 from public.profiles where id = auth.uid() and is_banned) then raise exception 'USER_BANNED'; end if;
end;
$$;

alter table public.profiles enable row level security;
alter table public.daily_quizzes enable row level security;
alter table public.questions enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.answers enable row level security;
alter table public.hint_uses enable row level security;
alter table public.check_ins enable row level security;
alter table public.rewarded_hint_claims enable row level security;

-- Users can only read/update their own profile. Admin operations use protected RPCs.
drop policy if exists profile_self_select on public.profiles;
create policy profile_self_select on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists profile_self_update on public.profiles;

-- Do not expose answer keys to normal users. Admins may read questions directly.
drop policy if exists admin_questions_select on public.questions;
create policy admin_questions_select on public.questions for select to authenticated using (public.is_admin());
drop policy if exists admin_questions_update on public.questions;
create policy admin_questions_update on public.questions for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Own attempt/history rows may be viewed. Writes happen through server RPCs.
drop policy if exists own_attempts_select on public.quiz_attempts;
create policy own_attempts_select on public.quiz_attempts for select to authenticated using (user_id = auth.uid());
drop policy if exists own_answers_select on public.answers;
create policy own_answers_select on public.answers for select to authenticated using (
  exists(select 1 from public.quiz_attempts a where a.id = attempt_id and a.user_id = auth.uid())
);
drop policy if exists own_checkins_select on public.check_ins;
create policy own_checkins_select on public.check_ins for select to authenticated using (user_id = auth.uid());
drop policy if exists own_rewards_select on public.rewarded_hint_claims;
create policy own_rewards_select on public.rewarded_hint_claims for select to authenticated using (user_id = auth.uid());


create or replace function public.update_username(p_username text)
returns void
language plpgsql
security definer set search_path = public
as $$
declare v_name text := trim(p_username);
begin
  perform public.assert_active_user();
  if char_length(v_name) < 2 or char_length(v_name) > 24 then raise exception 'INVALID_USERNAME'; end if;
  update public.profiles set username = v_name where id = auth.uid();
end;
$$;

create or replace function public.get_dashboard()
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  p public.profiles%rowtype;
  a public.quiz_attempts%rowtype;
  v_ready boolean;
begin
  perform public.assert_active_user();
  select * into p from public.profiles where id = auth.uid();
  select * into a from public.quiz_attempts where user_id = auth.uid() and quiz_date = public.app_today();
  select exists(
    select 1 from public.daily_quizzes d
    where d.quiz_date = public.app_today() and d.status = 'published'
      and (select count(*) from public.questions q where q.quiz_date = d.quiz_date) = 60
  ) into v_ready;

  return jsonb_build_object(
    'username', p.username,
    'role', p.role,
    'total_points', p.total_points,
    'hint_balance', p.hint_balance,
    'checked_in_today', exists(select 1 from public.check_ins c where c.user_id = auth.uid() and c.check_in_date = public.app_today()),
    'quiz_ready', v_ready,
    'attempt_status', coalesce(a.status, 'not_started'),
    'current_position', coalesce(a.current_position, 1),
    'correct_count', coalesce(a.correct_count, 0),
    'wrong_count', coalesce(a.wrong_count, 0),
    'points_earned', coalesce(a.points_earned, 0),
    'flagged', coalesce(a.flagged, false)
  );
end;
$$;

create or replace function public.daily_check_in()
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_rows bigint;
begin
  perform public.assert_active_user();
  insert into public.check_ins(user_id, check_in_date)
  values(auth.uid(), public.app_today())
  on conflict do nothing;
  get diagnostics v_rows = row_count;
  if v_rows = 1 then
    update public.profiles set hint_balance = hint_balance + 1 where id = auth.uid();
  end if;
  return public.get_dashboard();
end;
$$;

create or replace function public.start_or_resume_quiz()
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  a public.quiz_attempts%rowtype;
  v_questions jsonb;
begin
  perform public.assert_active_user();
  if not exists(
    select 1 from public.daily_quizzes d
    where d.quiz_date = public.app_today() and d.status = 'published'
      and (select count(*) from public.questions q where q.quiz_date = d.quiz_date) = 60
  ) then
    raise exception 'TODAY_QUIZ_NOT_READY';
  end if;

  insert into public.quiz_attempts(user_id, quiz_date)
  values(auth.uid(), public.app_today())
  on conflict (user_id, quiz_date) do nothing;

  select * into a from public.quiz_attempts where user_id = auth.uid() and quiz_date = public.app_today();

  select jsonb_agg(
    jsonb_build_object(
      'id', q.id,
      'position', q.position,
      'question', q.question_text,
      'options', q.options
    ) order by q.position
  ) into v_questions
  from public.questions q where q.quiz_date = public.app_today();

  return jsonb_build_object(
    'status', a.status,
    'current_position', a.current_position,
    'correct_count', a.correct_count,
    'wrong_count', a.wrong_count,
    'points_earned', a.points_earned,
    'flagged', a.flagged,
    'questions', coalesce(v_questions, '[]'::jsonb)
  );
end;
$$;

create or replace function public.submit_answer(p_question_id bigint, p_selected_index integer)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  a public.quiz_attempts%rowtype;
  q public.questions%rowtype;
  old_answer public.answers%rowtype;
  v_correct boolean;
  v_now timestamptz := now();
  v_rapid smallint;
  v_completed boolean;
  v_flagged boolean;
  v_reason text;
  v_new_correct smallint;
  v_new_wrong smallint;
  v_new_points integer;
  v_next smallint;
begin
  perform public.assert_active_user();
  if p_selected_index < 0 or p_selected_index > 3 then raise exception 'INVALID_OPTION'; end if;

  select * into a from public.quiz_attempts
  where user_id = auth.uid() and quiz_date = public.app_today()
  for update;
  if not found then raise exception 'ATTEMPT_NOT_STARTED'; end if;
  if a.status = 'completed' then raise exception 'QUIZ_ALREADY_COMPLETED'; end if;

  select * into q from public.questions
  where id = p_question_id and quiz_date = public.app_today() and position = a.current_position;
  if not found then raise exception 'QUESTION_OUT_OF_SEQUENCE'; end if;

  select * into old_answer from public.answers where attempt_id = a.id and question_id = q.id;
  if found then
    return jsonb_build_object(
      'is_correct', old_answer.is_correct,
      'correct_index', q.correct_index,
      'correct_count', a.correct_count,
      'wrong_count', a.wrong_count,
      'points_earned', a.points_earned,
      'current_position', a.current_position,
      'completed', a.status = 'completed',
      'flagged', a.flagged
    );
  end if;

  v_correct := p_selected_index = q.correct_index;
  v_rapid := a.rapid_answer_count + case when a.last_answer_at is not null and v_now - a.last_answer_at < interval '750 milliseconds' then 1 else 0 end;
  v_new_correct := a.correct_count + case when v_correct then 1 else 0 end;
  v_new_wrong := a.wrong_count + case when v_correct then 0 else 1 end;
  v_new_points := a.points_earned + case when v_correct then 10 else 0 end;
  v_completed := q.position = 60;
  v_next := case when v_completed then 61 else (q.position + 1)::smallint end;

  insert into public.answers(attempt_id, question_id, selected_index, is_correct, answered_at)
  values(a.id, q.id, p_selected_index, v_correct, v_now);

  v_flagged := a.flagged;
  v_reason := a.flag_reason;
  if v_completed then
    if v_now - a.started_at < interval '120 seconds' then
      v_flagged := true;
      v_reason := 'completed_under_120_seconds';
    elsif v_rapid >= 12 then
      v_flagged := true;
      v_reason := 'excessive_subsecond_answers';
    end if;
  end if;

  update public.quiz_attempts
  set correct_count = v_new_correct,
      wrong_count = v_new_wrong,
      points_earned = v_new_points,
      current_position = v_next,
      rapid_answer_count = v_rapid,
      last_answer_at = v_now,
      status = case when v_completed then 'completed' else 'active' end,
      completed_at = case when v_completed then v_now else null end,
      flagged = v_flagged,
      flag_reason = v_reason
  where id = a.id;

  if v_completed then
    update public.profiles
    set total_points = total_points + v_new_points,
        quizzes_completed = quizzes_completed + 1,
        total_correct = total_correct + v_new_correct,
        total_wrong = total_wrong + v_new_wrong,
        best_score = greatest(best_score, v_new_correct)
    where id = auth.uid();
  end if;

  return jsonb_build_object(
    'is_correct', v_correct,
    'correct_index', q.correct_index,
    'correct_count', v_new_correct,
    'wrong_count', v_new_wrong,
    'points_earned', v_new_points,
    'current_position', v_next,
    'completed', v_completed,
    'flagged', v_flagged
  );
end;
$$;

create or replace function public.use_hint(p_question_id bigint)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  a public.quiz_attempts%rowtype;
  q public.questions%rowtype;
  p public.profiles%rowtype;
begin
  perform public.assert_active_user();
  select * into a from public.quiz_attempts
  where user_id = auth.uid() and quiz_date = public.app_today() and status = 'active'
  for update;
  if not found then raise exception 'ATTEMPT_NOT_ACTIVE'; end if;
  select * into q from public.questions where id = p_question_id and quiz_date = public.app_today() and position = a.current_position;
  if not found then raise exception 'QUESTION_OUT_OF_SEQUENCE'; end if;

  if exists(select 1 from public.hint_uses where attempt_id = a.id and question_id = q.id) then
    select * into p from public.profiles where id = auth.uid();
    return jsonb_build_object('hint', q.hint, 'hint_balance', p.hint_balance, 'already_used', true);
  end if;

  select * into p from public.profiles where id = auth.uid() for update;
  if p.hint_balance <= 0 then raise exception 'NO_HINTS'; end if;
  update public.profiles set hint_balance = hint_balance - 1 where id = auth.uid();
  insert into public.hint_uses(attempt_id, question_id) values(a.id, q.id);
  return jsonb_build_object('hint', q.hint, 'hint_balance', p.hint_balance - 1, 'already_used', false);
end;
$$;

create or replace function public.get_my_stats()
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare p public.profiles%rowtype;
begin
  perform public.assert_active_user();
  select * into p from public.profiles where id = auth.uid();
  return jsonb_build_object(
    'total_points', p.total_points,
    'quizzes_completed', p.quizzes_completed,
    'total_correct', p.total_correct,
    'total_wrong', p.total_wrong,
    'best_score', p.best_score,
    'hint_balance', p.hint_balance
  );
end;
$$;

create or replace function public.get_checkin_history()
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare v_dates jsonb;
begin
  perform public.assert_active_user();
  select coalesce(jsonb_agg(c.check_in_date order by c.check_in_date desc), '[]'::jsonb)
  into v_dates from (
    select check_in_date from public.check_ins where user_id = auth.uid() order by check_in_date desc limit 90
  ) c;
  return jsonb_build_object('dates', v_dates);
end;
$$;

create or replace function public.get_leaderboard(p_period text)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_top jsonb;
  v_me jsonb;
  v_start date;
begin
  perform public.assert_active_user();
  if p_period not in ('daily','weekly','all_time') then raise exception 'INVALID_PERIOD'; end if;
  v_start := case
    when p_period = 'daily' then public.app_today()
    when p_period = 'weekly' then date_trunc('week', public.app_today()::timestamp)::date
    else date '2000-01-01'
  end;

  with scores as (
    select a.user_id,
           sum(a.points_earned)::int as points,
           sum(a.correct_count)::int as correct,
           min(a.completed_at) as completed_at
    from public.quiz_attempts a
    where a.quiz_date between v_start and public.app_today()
      and not a.flagged
    group by a.user_id
  ), ranked as (
    select s.user_id, p.username, s.points, s.correct,
           (row_number() over(order by s.points desc, s.correct desc, s.completed_at asc nulls last, s.user_id))::int as rank
    from scores s join public.profiles p on p.id = s.user_id
    where not p.is_banned
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'rank', r.rank,
    'username', r.username,
    'points', r.points,
    'correct', r.correct,
    'is_current_user', r.user_id = auth.uid()
  ) order by r.rank), '[]'::jsonb)
  into v_top
  from (select * from ranked order by rank limit 100) r;

  with scores as (
    select a.user_id,
           sum(a.points_earned)::int as points,
           sum(a.correct_count)::int as correct,
           min(a.completed_at) as completed_at
    from public.quiz_attempts a
    where a.quiz_date between v_start and public.app_today()
      and not a.flagged
    group by a.user_id
  ), ranked as (
    select s.user_id, p.username, s.points, s.correct,
           (row_number() over(order by s.points desc, s.correct desc, s.completed_at asc nulls last, s.user_id))::int as rank
    from scores s join public.profiles p on p.id = s.user_id
    where not p.is_banned
  )
  select jsonb_build_object(
    'rank', r.rank,
    'username', r.username,
    'points', r.points,
    'correct', r.correct,
    'is_current_user', true
  ) into v_me from ranked r where r.user_id = auth.uid();

  return jsonb_build_object('top', v_top, 'me', v_me);
end;
$$;

create or replace function public.admin_get_today_questions()
returns table(id bigint, position smallint, question_text text, options jsonb, correct_index smallint, hint text)
language plpgsql
security definer set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  return query select q.id, q.position, q.question_text, q.options, q.correct_index, q.hint
  from public.questions q where q.quiz_date = public.app_today() order by q.position;
end;
$$;

create or replace function public.admin_update_question(
  p_question_id bigint,
  p_question_text text,
  p_options jsonb,
  p_correct_index integer,
  p_hint text
)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  if jsonb_typeof(p_options) <> 'array' or jsonb_array_length(p_options) <> 4 then raise exception 'FOUR_OPTIONS_REQUIRED'; end if;
  if p_correct_index < 0 or p_correct_index > 3 then raise exception 'INVALID_CORRECT_INDEX'; end if;
  update public.questions
  set question_text = trim(p_question_text), options = p_options, correct_index = p_correct_index, hint = trim(p_hint)
  where id = p_question_id and quiz_date = public.app_today();
  if not found then raise exception 'QUESTION_NOT_FOUND'; end if;
end;
$$;

create or replace function public.admin_list_users()
returns table(id uuid, username text, total_points integer, is_banned boolean, flagged_attempts bigint)
language plpgsql
security definer set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  return query
  select p.id, p.username, p.total_points, p.is_banned,
         (select count(*) from public.quiz_attempts a where a.user_id = p.id and a.flagged) as flagged_attempts
  from public.profiles p order by p.created_at desc limit 500;
end;
$$;

create or replace function public.admin_set_user_banned(p_user_id uuid, p_banned boolean)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'ADMIN_REQUIRED'; end if;
  if p_user_id = auth.uid() and p_banned then raise exception 'CANNOT_BAN_SELF'; end if;
  update public.profiles set is_banned = p_banned where id = p_user_id;
end;
$$;


create or replace function public.service_claim_rewarded_hint(p_user_id uuid)
returns integer
language plpgsql
security definer set search_path = public
as $$
declare
  v_balance integer;
  v_last timestamptz;
  v_count bigint;
begin
  select max(claimed_at), count(*) filter (where (timezone('Asia/Karachi', claimed_at))::date = public.app_today())
  into v_last, v_count
  from public.rewarded_hint_claims where user_id = p_user_id;

  if v_last is not null and now() - v_last < interval '10 seconds' then
    raise exception 'REWARD_RATE_LIMIT';
  end if;
  if v_count >= 60 then
    raise exception 'REWARD_DAILY_LIMIT';
  end if;
  if exists(select 1 from public.profiles where id = p_user_id and is_banned) then
    raise exception 'USER_BANNED';
  end if;

  insert into public.rewarded_hint_claims(user_id) values(p_user_id);
  update public.profiles set hint_balance = hint_balance + 1 where id = p_user_id
  returning hint_balance into v_balance;
  return v_balance;
end;
$$;

-- RPC permissions
revoke all on function public.assert_active_user() from public;
revoke all on function public.is_admin() from public;
revoke all on function public.service_claim_rewarded_hint(uuid) from public;
grant execute on function public.service_claim_rewarded_hint(uuid) to service_role;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.update_username(text) to authenticated;
grant execute on function public.get_dashboard() to authenticated;
grant execute on function public.daily_check_in() to authenticated;
grant execute on function public.start_or_resume_quiz() to authenticated;
grant execute on function public.submit_answer(bigint, integer) to authenticated;
grant execute on function public.use_hint(bigint) to authenticated;
grant execute on function public.get_my_stats() to authenticated;
grant execute on function public.get_checkin_history() to authenticated;
grant execute on function public.get_leaderboard(text) to authenticated;
grant execute on function public.admin_get_today_questions() to authenticated;
grant execute on function public.admin_update_question(bigint, text, jsonb, integer, text) to authenticated;
grant execute on function public.admin_list_users() to authenticated;
grant execute on function public.admin_set_user_banned(uuid, boolean) to authenticated;
