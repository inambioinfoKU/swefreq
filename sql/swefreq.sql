-- Script for creating the swefreq tables. To run this file use:
-- mysql databasename <swefreq.sql
-- Possibly with mysql credentials


CREATE TABLE IF NOT EXISTS user (
    user_pk             INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    name                VARCHAR(100)    DEFAULT NULL,
    email               VARCHAR(100)    NOT NULL,
    affiliation         VARCHAR(100)    DEFAULT NULL,
    country             VARCHAR(100)    DEFAULT NULL,
    CONSTRAINT UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS dataset (
    dataset_pk          INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    sample_set_pk       INTEGER         NOT NULL,
    short_name          VARCHAR(50)     NOT NULL,
    full_name           VARCHAR(100)    NOT NULL,
    browser_uri         VARCHAR(200)    DEFAULT NULL,
    beacon_uri          VARCHAR(200)    DEFAULT NULL,
    avg_seq_depth       FLOAT           DEFAULT NULL,
    seq_type            VARCHAR(50)     DEFAULT NULL,
    seq_tech            VARCHAR(50)     DEFAULT NULL,
    seq_center          VARCHAR(100)    DEFAULT NULL,
    dataset_size        INTEGER         UNSIGNED NOT NULL,
    CONSTRAINT UNIQUE (short_name),
    CONSTRAINT FOREIGN KEY (sample_set_pk)
        REFERENCES sample_set(sample_set_pk)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS user_log (
    user_log_pk         INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    user_pk             INTEGER         NOT NULL,
    dataset_pk          INTEGER         NOT NULL,
    action  ENUM ('consent','download',
                  'access_requested','access_granted','access_revoked',
                  'private_link')       DEFAULT NULL,
    ts                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FOREIGN KEY (user_pk)    REFERENCES user(user_pk),
    CONSTRAINT FOREIGN KEY (dataset_pk) REFERENCES dataset(dataset_pk)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS dataset_access (
    dataset_access_pk   INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    dataset_pk          INTEGER         NOT NULL,
    user_pk             INTEGER         NOT NULL,
    wants_newsletter    BOOLEAN         DEFAULT false,
    is_admin            BOOLEAN         DEFAULT false,
    has_consented       BOOLEAN         DEFAULT false,
    has_access          BOOLEAN         DEFAULT false,
    CONSTRAINT UNIQUE (dataset_pk, user_pk),
    CONSTRAINT FOREIGN KEY (dataset_pk) REFERENCES dataset(dataset_pk),
    CONSTRAINT FOREIGN KEY (user_pk)    REFERENCES user(user_pk)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS dataset_version (
    dataset_version_pk  INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    dataset_pk          INTEGER         NOT NULL,
    version             VARCHAR(20)     NOT NULL,
    is_current          BOOLEAN         DEFAULT true,
    description         TEXT            NOT NULL,
    terms               TEXT            NOT NULL,
    var_call_ref        VARCHAR(50)     DEFAULT NULL,
    available_from_ts   TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    ref_doi             VARCHAR(100)    DEFAULT NULL,
    CONSTRAINT FOREIGN KEY (dataset_pk) REFERENCES dataset(dataset_pk)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS dataset_file (
    dataset_file_pk     INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    dataset_version_pk  INTEGER         NOT NULL,
    name                VARCHAR(100)    NOT NULL,
    uri                 VARCHAR(200)    NOT NULL,
    CONSTRAINT FOREIGN KEY (dataset_version_pk)
        REFERENCES dataset_version(dataset_version_pk)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS dataset_logo (
    dataset_logo_pk     INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    dataset_pk          INTEGER         NOT NULL,
    mimetype            VARCHAR(50)     NOT NULL,
    data                MEDIUMBLOB      NOT NULL,
    CONSTRAINT UNIQUE (dataset_pk),
    CONSTRAINT FOREIGN KEY (dataset_pk) REFERENCES dataset(dataset_pk)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS linkhash (
    linkhash_pk         INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    dataset_verison_pk  INTEGER         NOT NULL,
    user_pk             INTEGER         NOT NULL,
    hash                VARCHAR(64)     NOT NULL,
    expires_ts          TIMESTAMP       NOT NULL,
    CONSTRAINT FOREIGN KEY (dataset_version_pk)
        REFERENCES dataset_version(dataset_version_pk),
    CONSTRAINT FOREIGN KEY (user_pk) REFERENCES user(user_pk)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Extra tables for dataset meta-data:

CREATE TABLE IF NOT EXISTS study (
    study_pk            INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    pi_name             VARCHAR(100)    NOT NULL,
    pi_email            VARCHAR(100)    NOT NULL,
    contact_name        VARCHAR(100)    NOT NULL,
    contact_email       VARCHAR(100)    NOT NULL,
    title               VARCHAR(100)    NOT NULL,
    description         TEXT            DEFAULT NULL,
    ts                  TIMESTAMP       NOT NULL,
    ref_doi             VARCHAR(100)    DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS sample_set (
    sample_set_pk       INTEGER         NOT NULL PRIMARY KEY AUTO_INCREMENT,
    study_pk            INTEGER         NOT NULL,
    ethnicity           VARCHAR(50)     DEFAULT NULL,
    collection          VARCHAR(100)    DEFAULT NULL,
    sample_size         INTEGER         NOT NULL,
    CONSTRAINT FOREIGN KEY (study_pk) REFERENCES study(study_pk)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- dataset_version_current, a view that only contains the (most) current
-- version of each entry dataset_version

CREATE OR REPLACE VIEW dataset_version_current AS
    SELECT * FROM dataset_version
    WHERE (dataset_pk,dataset_version_pk) IN (
        SELECT dataset_pk, MAX(dataset_version_pk) FROM dataset_version
        WHERE available_from_ts < now()
        GROUP BY dataset_pk );
