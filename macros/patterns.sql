{#- Default detection patterns. Override them with the vars of the same name.
    Patterns are matched against lowercase values. -#}

{% macro bot_user_agent_pattern() -%}
    {{ return(var('segment_bot_audit_bot_ua_pattern',
        'bot|crawl|spider|slurp|headless|phantomjs|puppeteer|playwright|selenium|webdriver'
        ~ '|python|curl/|wget|httpclient|okhttp|axios|node-fetch|go-http|java/|libwww|scrapy'
        ~ '|lighthouse|pagespeed|pingdom|uptime|statuscake|site24x7|datadog|newrelic'
        ~ '|facebookexternalhit|preview|ahrefs|semrush|mj12|dataforseo|petal|bytespider'
        ~ '|gptbot|chatgpt|claude|anthropic|perplexity|ccbot|cohere|diffbot')) }}
{%- endmacro %}

{#- Real user agents that the bot pattern matches by mistake. -#}
{% macro bot_user_agent_exclusion_pattern() -%}
    {{ return(var('segment_bot_audit_bot_ua_exclusion_pattern', 'cubot')) }}
{%- endmacro %}

{% macro scanner_path_pattern() -%}
    {{ return(var('segment_bot_audit_scanner_path_pattern',
        'wp-login|wp-admin|xmlrpc|wp-config|phpmyadmin|cgi-bin|/[.](env|git|aws|ssh|htaccess|ds_store)'
        ~ '|/vendor/phpunit|/actuator|/solr/|/owa/|/boaform|eval-stdin')) }}
{%- endmacro %}
