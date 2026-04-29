import "LUI.src.Utils.search_query"

function parse_query(query)
    return SearchQuery.parse_text_groups(query)
end

function normalize_groups(groups)
    return SearchQuery.normalize_groups(groups)
end

function matches_groups(groups, haystack_lower)
    return SearchQuery.matches_groups(groups, haystack_lower)
end
