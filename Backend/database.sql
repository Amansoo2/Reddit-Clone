DROP TABLE IF EXISTS comments;
CREATE TABLE public.comments ( /*public is the default postgres schema*/
    id integer NOT NULL, /*This id integer value gives a unique identifier for every comment*/
    user_id integer NOT NULL,
    post_id integer NOT NULL, /*This id associates each comment with the post ID it's replying to*/
    parent_id integer, /*Column used to establish structure among comments. If reply or not. If top-level, can be nullable*/
    has_parent boolean, /*Column that checks if it's a reply or not. True if reply, false if not*/
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    is_edited boolean DEFAULT false
);

DROP TABLE IF EXISTS posts;
CREATE TABLE public.posts (
    id integer NOT NULL,
    user_id integer NOT NULL,
    subreddit_id integer NOT NULL, /*This id is associated with the subreddit id it's posted on*/
    title text NOT NULL,
    media text, /* This stores reference to media files */
    content text, /* This stores the textual content of the post */
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    is_edited boolean DEFAULT false
);

DROP TABLE IF EXISTS reactions;
CREATE TABLE public.reactions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    post_id integer,
    comment_id integer,
    is_upvote boolean NOT NULL, /*This is_upvote column checks if the reaction is an upvote or not*/
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS users;
CREATE TABLE public.users (
    id integer NOT NULL,
    username text NOT NULL,
    password_hash text NOT NULL,
    email text NOT NULL,
    avatar text,
    bio text,
    registration_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

DROP VIEW IF EXISTS comments_info;
CREATE VIEW public.comments_info AS /*We're creating a virtual table to get everything we need to know about a comment*/
SELECT c.id AS comment_id,  /*Create a column from the alias "c" (i.e comments table) and name it comment_id*/
u.username AS user_name,
u.avatar AS user_avatar,
ckarma.comment_karma, /*Include all the following in this virtual table*/
c.has_parent, 
c.parent_id,
c.is_edited,
c.content,
c.created_at,
p.id AS post_id
FROM (((public.posts p
FULL JOIN public.comments c on ((c.post_id = p.id))) /*We connect post table with comments. We connect rows where post id in comments matches id in posts */
FULL JOIN (SELECT c_1.id AS comment_id, /* Get the id column from alias c_1 and call it comment_id*/
COALESCE(sum( /*COALESCE returns the first non-null value*/
    CASE
        WHEN (r.is_upvote = True) THEN 1
        WHEN (r.is_upvote = False) THEN '-1'::integer
        ELSE 0
    END), (0)::bigint) AS comment_karma
FROM (public.comments c_1
FULL JOIN public.reactions r ON ((r.comment_id = c_1.id)))
GROUP BY c_1.id   /*We group by each comments id to do each karma calculation seperately*/
HAVING (c_1.id IS NOT NULL)) ckarma ON ((ckarma.comment_id = c.id))) /*This HAVING clause excludes any null id's from the id column in comments table */
FULL JOIN public.users u ON ((u.id = c.user_id)));


CREATE SEQUENCE public.comments_id_seq /* Create a sequence that acts as the unique identifier # */
AS integer
START WITH 1
INCREMENT BY 1
NO MINVALUE /* Set this so there is no minimum value for the sequence */
NO MAXVALUE
CACHE 1; /* Sequence must only generate one value at a time. */

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;  /* We now assign this sequence to the id column of comments table */

CREATE TABLE public.subreddit (
    id integer NOT NULL,
    name character varying(20) NOT NULL, /* This creates a column with subreddit name which must be 20 characters or less */
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    logo text,
    created_by integer
);

CREATE VIEW public.post_info AS
SELECT t.id AS thread_id,
t.name AS thread_name,
t.logo AS thread_logo,
p.id AS post_id,
k.karma AS post_karma,
p.title,
p.media,
p.is_edited,
p.content,
p.created_at,
u.id AS user_id,
u.username AS user_name,
u.avatar AS user_avatar,
c.comments_count
FROM ((((public.posts p
JOIN ( SELECT p_1.id AS post_id, /* We give the subquery an Alias p_1. We join the result of the subquery(post_id/Karma) with posts table */
COALESCE (sum( /* We now calculate the post karma */
    CASE
        WHEN (r.is_upvote = true) THEN 1
        WHEN (r.is_upvote = false) THEN '-1'::integer
        ELSE 0
    END), (0)::bigint) AS KARMA
FROM (public.posts p_1
FULL JOIN public.reactions r ON ((r.post_id = p_1.id))) /* We fully join the posts table with reactions table, and based on the condition that reactions post_id should match posts id */
GROUP BY p_1.id) k ON ((k.post_id = p.id))) /* Group results of join based on the id column, meaning we have one row for each unique p_1.id column. Then join the result of previous grouping with another table */
JOIN ( SELECT p_1.id AS post_id,
count(c_1.id) AS comments_count /*This counts the number of comments by counting the number of rows in the id column of comments table */
FROM (public.posts p_1
FULL JOIN public.comments c_1 ON ((c_1.post_id = p_1.id))) /* We join the comments table with posts table, matching condition is where comment id = post id */
GROUP BY p_1.id) c ON ((c.post_id = p.id)))
JOIN public.subreddit t ON ((t.id = p.subreddit_id)))
JOIN public.users u ON ((u.id = p.user_id)));

CREATE SEQUENCE public.posts_id_seq /* Just like we created a comments id sequence, we create a post id sequence */
AS integer
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id; /* Assign this sequence to the id column of posts table */

CREATE SEQUENCE public.reactions_id_seq 
AS integer
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

ALTER SEQUENCE public.reactions_id_seq OWNED BY public.reactions.id;

CREATE TABLE public.roles (
    id integer NOT NULL,
    name text NOT NULL,
    slug text NOT NULL /* Create a more readble url of the name */
);

CREATE SEQUENCE public.roles_id_seq
AS integer
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;

CREATE TABLE public.saved (
    id integer NOT NULL,
    user_id integer NOT NULL,
    post_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE SEQUENCE public.saved_id_seq
AS integer
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

ALTER SEQUENCE public.saved_id_seq OWNED BY public.saved.id;

CREATE TABLE public.subscriptions(
    id integer NOT NULL,
    user_id integer NOT NULL,
    subreddit_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE SEQUENCE public.subcriptions_id_seq
AS integer
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;

CREATE VIEW public.subreddit_info AS
SELECT subreddit.id,
subreddit.name,
subreddit.logo,
mcount.members_count,
pcount.posts_count,
ccount.comments_count,

FROM (((public.subreddit
FULL JOIN ( SELECT subreddit_1.id AS subreddit_id, /* We want to join the subreddit table with 3 subquerys: */
count(*) AS members_count /* This counts the # of rows in members_count */
FROM (public.subreddit subreddit_1
JOIN public.subscriptions ON ((subscriptions.subreddit_id = subreddit_1.id )))
GROUP BY subreddit_1.id) mcount ON ((mcount.subreddit_id = subreddit.id))) /* First subquery (mcount) counts the number of members(subsctiptions) for each subthread */

FULL JOIN ( SELECT subreddit.id AS subreddit_id,
count(*) AS posts_count 
FROM (public.subreddit subreddit_1
JOIN public.posts ON ((posts.subreddit_1 = subreddit_1.id)))
GROUP BY subreddit_1.id) pcount ON ((pcount.subreddit_id = subreddit.id))) /* 2nd subquery (pcount) counts the number of posts for each subreddit */

FULL JOIN ( SELECT subreddit_1.id AS subreddit_id,
count(*) AS comments_count
FROM ((public.subreddit subreddit_1
JOIN public.posts ON ((posts.subreddit_id = subreddit_1.id))) /* Within the 3rd subquery, we join the posts table with subbredit table with the matching condition that subreddit id in posts matches subreddit id in subreddit table */
JOIN public.comments ON ((comments.post_id = posts.id))) /* We then join the comments table with posts table with matching condition that post id in comments table matches the id in the posts table */
GROUP BY subreddit_1.id) ccount ON ((ccount.subreddit_id = subreddit.id))); /* Group the results in the subquery by the id of the subreddit, and then finally join the result of the subquery (ccount) with the main source (subreddit table) */

CREATE SEQUENCE public.subreddit_id_seq
AS integer
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 1;

ALTER SEQUENCE public.subreddit_id_seq OWNED BY public.subreddit.id;

CREATE VIEW public.user_info AS
SELECT u.id AS user_id,
(c.karma + p.karma) AS user_karma,
c.comments_count,
c.karma AS comments_karma,
p.posts_count, 
p.karma AS 















