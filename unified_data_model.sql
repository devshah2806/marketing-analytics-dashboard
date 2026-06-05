-- ============================================================
-- CROSS-CHANNEL MARKETING UNIFIED DATA MODEL
-- Platforms: Facebook Ads, Google Ads, TikTok Ads
-- Period: January 2024
-- ============================================================

-- ============================================================
-- 1. SOURCE TABLES
-- ============================================================

CREATE TABLE facebook_ads (
    date                DATE,
    campaign_id         VARCHAR(20),
    campaign_name       VARCHAR(100),
    ad_set_id           VARCHAR(20),
    ad_set_name         VARCHAR(100),
    impressions         BIGINT,
    clicks              BIGINT,
    spend               NUMERIC(10,2),
    conversions         INT,
    video_views         BIGINT,
    engagement_rate     NUMERIC(6,4),
    reach               BIGINT,
    frequency           NUMERIC(5,2)
);

CREATE TABLE google_ads (
    date                    DATE,
    campaign_id             VARCHAR(20),
    campaign_name           VARCHAR(100),
    ad_group_id             VARCHAR(20),
    ad_group_name           VARCHAR(100),
    impressions             BIGINT,
    clicks                  BIGINT,
    cost                    NUMERIC(10,2),
    conversions             INT,
    conversion_value        NUMERIC(10,2),
    ctr                     NUMERIC(6,4),
    avg_cpc                 NUMERIC(6,2),
    quality_score           INT,
    search_impression_share NUMERIC(5,2)
);

CREATE TABLE tiktok_ads (
    date                DATE,
    campaign_id         VARCHAR(20),
    campaign_name       VARCHAR(100),
    adgroup_id          VARCHAR(20),
    adgroup_name        VARCHAR(100),
    impressions         BIGINT,
    clicks              BIGINT,
    cost                NUMERIC(10,2),
    conversions         INT,
    video_views         BIGINT,
    video_watch_25      BIGINT,
    video_watch_50      BIGINT,
    video_watch_75      BIGINT,
    video_watch_100     BIGINT,
    likes               BIGINT,
    shares              BIGINT,
    comments            BIGINT
);

-- ============================================================
-- 2. UNIFIED TABLE
-- Normalizes all three platforms to a common schema
-- Platform-specific metrics stored as nullable columns
-- ============================================================

CREATE TABLE unified_ads (
    -- Identity
    id                  SERIAL PRIMARY KEY,
    date                DATE          NOT NULL,
    platform            VARCHAR(20)   NOT NULL,   -- 'Facebook' | 'Google' | 'TikTok'
    campaign_id         VARCHAR(20)   NOT NULL,
    campaign_name       VARCHAR(100)  NOT NULL,
    ad_group_id         VARCHAR(20),
    ad_group_name       VARCHAR(100),

    -- Universal performance metrics
    impressions         BIGINT        NOT NULL,
    clicks              BIGINT        NOT NULL,
    cost                NUMERIC(10,2) NOT NULL,
    conversions         INT           NOT NULL,
    video_views         BIGINT        DEFAULT 0,

    -- Derived efficiency metrics (computed on insert)
    ctr                 NUMERIC(8,6)  GENERATED ALWAYS AS (
                            CASE WHEN impressions > 0
                                 THEN ROUND(clicks::NUMERIC / impressions, 6)
                                 ELSE 0 END
                        ) STORED,
    cpc                 NUMERIC(10,4) GENERATED ALWAYS AS (
                            CASE WHEN clicks > 0
                                 THEN ROUND(cost / clicks, 4)
                                 ELSE 0 END
                        ) STORED,
    cpa                 NUMERIC(10,4) GENERATED ALWAYS AS (
                            CASE WHEN conversions > 0
                                 THEN ROUND(cost / conversions, 4)
                                 ELSE 0 END
                        ) STORED,
    cpm                 NUMERIC(10,4) GENERATED ALWAYS AS (
                            CASE WHEN impressions > 0
                                 THEN ROUND(cost / impressions * 1000, 4)
                                 ELSE 0 END
                        ) STORED,

    -- Platform-specific metrics (nullable)
    -- Facebook
    engagement_rate     NUMERIC(6,4),
    reach               BIGINT,
    frequency           NUMERIC(5,2),

    -- Google
    conversion_value    NUMERIC(10,2),
    avg_cpc             NUMERIC(6,2),
    quality_score       INT,
    search_impression_share NUMERIC(5,2),

    -- TikTok
    video_watch_25      BIGINT,
    video_watch_50      BIGINT,
    video_watch_75      BIGINT,
    video_watch_100     BIGINT,
    likes               BIGINT,
    shares              BIGINT,
    comments            BIGINT,

    -- Audit
    loaded_at           TIMESTAMP     DEFAULT NOW()
);

-- ============================================================
-- 3. INSERT: Populate unified table from source tables
-- ============================================================

-- Facebook
INSERT INTO unified_ads (
    date, platform, campaign_id, campaign_name, ad_group_id, ad_group_name,
    impressions, clicks, cost, conversions, video_views,
    engagement_rate, reach, frequency
)
SELECT
    date, 'Facebook', campaign_id, campaign_name, ad_set_id, ad_set_name,
    impressions, clicks, spend, conversions, video_views,
    engagement_rate, reach, frequency
FROM facebook_ads;

-- Google
INSERT INTO unified_ads (
    date, platform, campaign_id, campaign_name, ad_group_id, ad_group_name,
    impressions, clicks, cost, conversions, video_views,
    conversion_value, avg_cpc, quality_score, search_impression_share
)
SELECT
    date, 'Google', campaign_id, campaign_name, ad_group_id, ad_group_name,
    impressions, clicks, cost, conversions, 0,
    conversion_value, avg_cpc, quality_score, search_impression_share
FROM google_ads;

-- TikTok
INSERT INTO unified_ads (
    date, platform, campaign_id, campaign_name, ad_group_id, ad_group_name,
    impressions, clicks, cost, conversions, video_views,
    video_watch_25, video_watch_50, video_watch_75, video_watch_100,
    likes, shares, comments
)
SELECT
    date, 'TikTok', campaign_id, campaign_name, adgroup_id, adgroup_name,
    impressions, clicks, cost, conversions, video_views,
    video_watch_25, video_watch_50, video_watch_75, video_watch_100,
    likes, shares, comments
FROM tiktok_ads;

-- ============================================================
-- 4. INDEXES for dashboard query performance
-- ============================================================

CREATE INDEX idx_unified_date       ON unified_ads (date);
CREATE INDEX idx_unified_platform   ON unified_ads (platform);
CREATE INDEX idx_unified_campaign   ON unified_ads (campaign_name);
CREATE INDEX idx_unified_date_plat  ON unified_ads (date, platform);

-- ============================================================
-- 5. ANALYTICAL VIEWS
-- ============================================================

-- Platform summary
CREATE VIEW vw_platform_summary AS
SELECT
    platform,
    SUM(impressions)    AS total_impressions,
    SUM(clicks)         AS total_clicks,
    SUM(cost)           AS total_spend,
    SUM(conversions)    AS total_conversions,
    SUM(video_views)    AS total_video_views,
    ROUND(SUM(clicks)::NUMERIC / NULLIF(SUM(impressions), 0) * 100, 2) AS ctr_pct,
    ROUND(SUM(cost) / NULLIF(SUM(clicks), 0), 2)                       AS avg_cpc,
    ROUND(SUM(cost) / NULLIF(SUM(conversions), 0), 2)                  AS avg_cpa,
    ROUND(SUM(cost) / NULLIF(SUM(impressions), 0) * 1000, 2)           AS avg_cpm
FROM unified_ads
GROUP BY platform
ORDER BY total_spend DESC;

-- Campaign performance
CREATE VIEW vw_campaign_performance AS
SELECT
    platform,
    campaign_name,
    SUM(impressions)    AS total_impressions,
    SUM(clicks)         AS total_clicks,
    SUM(cost)           AS total_spend,
    SUM(conversions)    AS total_conversions,
    ROUND(SUM(clicks)::NUMERIC / NULLIF(SUM(impressions), 0) * 100, 2) AS ctr_pct,
    ROUND(SUM(cost) / NULLIF(SUM(conversions), 0), 2)                  AS cpa,
    RANK() OVER (ORDER BY SUM(cost) / NULLIF(SUM(conversions), 0))     AS cpa_rank
FROM unified_ads
GROUP BY platform, campaign_name;

-- Daily trend
CREATE VIEW vw_daily_trend AS
SELECT
    date,
    platform,
    SUM(impressions) AS impressions,
    SUM(clicks)      AS clicks,
    SUM(cost)        AS spend,
    SUM(conversions) AS conversions
FROM unified_ads
GROUP BY date, platform
ORDER BY date, platform;
