
CREATE TYPE difficulty_level AS ENUM ('easy', 'medium', 'hard');
CREATE TYPE dependency_type AS ENUM ('prerequisite', 'corequisite', 'supplementary');
CREATE TYPE status_enum AS ENUM ('pending', 'accepted', 'rejected', 'blocked');
CREATE TYPE role_enum AS ENUM ('admin', 'moderator', 'member');
CREATE TYPE visibility_enum AS ENUM ('public', 'private', 'restricted');
CREATE TYPE visibility_scope AS ENUM ('private', 'group', 'public');
CREATE TYPE note_type AS ENUM ('text', 'document', 'link', 'multimedia');
CREATE TYPE presence_enum AS ENUM ('online', 'offline', 'away', 'busy');
CREATE TYPE interaction_enum AS ENUM ('audio_video', 'whiteboard', 'chat');
CREATE TYPE action_enum AS ENUM ('joined', 'left', 'started_whiteboard', 'ended_whiteboard', 'sent_message');


CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    user_email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    salt VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    avatar_public_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE oauth_accounts (
    oauth_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    provider VARCHAR(255) NOT NULL,
    providerAccountId VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (provider, providerAccountId)
);

CREATE TABLE user_email_verification (
    verification_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    user_email VARCHAR(255) NOT NULL,
    otp_code VARCHAR(10) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE learning_module (
    module_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    tags JSONB,
    estimated_duration INT,
    assessment_link TEXT,
    difficulty_level difficulty_level,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE learning_path (
    path_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    user_query TEXT,
    user_goal TEXT,
    progress JSONB,
    is_customized BOOLEAN DEFAULT FALSE,
    difficulty_level difficulty_level,
    tags TEXT[],
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE module_dependency (
    dependency_id SERIAL PRIMARY KEY,
    module_id INT NOT NULL REFERENCES learning_module(module_id) ON DELETE CASCADE,
    prerequisite_id INT[] NOT NULL,
    dependency_type dependency_type,
    is_optional BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE citation (
    citation_id SERIAL PRIMARY KEY,
    citation_text TEXT NOT NULL,
    citation_url TEXT UNIQUE,
    source_type TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE module_citation (
    module_citation_id SERIAL PRIMARY KEY,
    module_id INT NOT NULL REFERENCES learning_module(module_id) ON DELETE CASCADE,
    citation_id INT NOT NULL REFERENCES citation(citation_id) ON DELETE CASCADE,
    UNIQUE (module_id, citation_id)
);

CREATE TABLE learning_path_module (
    path_module_id SERIAL PRIMARY KEY,
    path_id INT NOT NULL REFERENCES learning_path(path_id) ON DELETE CASCADE,
    module_id INT NOT NULL REFERENCES learning_module(module_id) ON DELETE CASCADE,
    position INT NOT NULL,
    is_optional BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (path_id, module_id)
);

CREATE TABLE user_module_progress (
    module_progress_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    module_id INT NOT NULL REFERENCES learning_module(module_id) ON DELETE CASCADE,
    path_id INT NOT NULL REFERENCES learning_path(path_id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    completion_percent NUMERIC(5,2) DEFAULT 0.00,
    last_accessed TIMESTAMP DEFAULT NOW(),
    UNIQUE (user_id, module_id, path_id)
);

CREATE TABLE friend_request (
    request_id SERIAL PRIMARY KEY,
    sender_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    receiver_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    status status_enum DEFAULT 'pending',
    sent_at TIMESTAMP DEFAULT NOW(),
    accepted_at TIMESTAMP
);

CREATE TABLE study_group (
    group_id SERIAL PRIMARY KEY,
    group_name VARCHAR(255) NOT NULL,
    created_by INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    description TEXT,
    visibility visibility_enum DEFAULT 'public',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE study_group_membership (
    membership_id SERIAL PRIMARY KEY,
    group_id INT NOT NULL REFERENCES study_group(group_id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    role role_enum DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT NOW(),
    left_at TIMESTAMP
);

CREATE TABLE study_note (
    note_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT,
    visibility_scope visibility_scope DEFAULT 'private',
    related_module_id INT REFERENCES learning_module(module_id) ON DELETE SET NULL,
    is_shared BOOLEAN DEFAULT FALSE,
    shared_with_group_id INT REFERENCES study_group(group_id) ON DELETE SET NULL,
    note_type note_type DEFAULT 'text',
    tags JSONB,
    attachments JSONB,
    like_count INT DEFAULT 0,
    view_count INT DEFAULT 0,
    last_edited_by INT REFERENCES users(user_id),
    forked_from_note_id INT REFERENCES study_note(note_id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE note_comment (
    comment_id SERIAL PRIMARY KEY,
    note_id INT NOT NULL REFERENCES study_note(note_id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE meta_space (
    space_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    layout_config JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE meta_space_user_presence (
    presence_id SERIAL PRIMARY KEY,
    space_id INT NOT NULL REFERENCES meta_space(space_id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    x_coord INT DEFAULT 0,
    y_coord INT DEFAULT 0,
    orientation VARCHAR(50),
    status presence_enum DEFAULT 'online',
    last_updated TIMESTAMP DEFAULT NOW(),
    UNIQUE (space_id, user_id)
);

CREATE TABLE meta_interaction_group (
    group_id SERIAL PRIMARY KEY,
    space_id INT NOT NULL REFERENCES meta_space(space_id) ON DELETE CASCADE,
    interaction_type interaction_enum NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    ended_at TIMESTAMP
);

CREATE TABLE meta_interaction_group_members (
    group_member_id SERIAL PRIMARY KEY,
    group_id INT NOT NULL REFERENCES meta_interaction_group(group_id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    joined_at TIMESTAMP DEFAULT NOW(),
    left_at TIMESTAMP,
    UNIQUE (group_id, user_id)
);

CREATE TABLE meta_interaction_log (
    interaction_id SERIAL PRIMARY KEY,
    group_id INT NOT NULL REFERENCES meta_interaction_group(group_id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    action_type action_enum NOT NULL,
    metadata JSONB,
    timestamp TIMESTAMP DEFAULT NOW()
);
