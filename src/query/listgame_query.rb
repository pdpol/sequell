require 'query/listgame_parser'
require 'sql/query_list'
require 'query/ast/ast_query_builder'

module Query
  # Parslet grammar backed listgame query.
  class ListgameQuery
    def self.parse(default_nick, query)
      self.new(default_nick, QueryString.query(query))
    end

    attr_reader :default_nick

    def initialize(default_nick, query)
      @default_nick = default_nick
      @query = query
    end

    def ast
      @ast ||= Query::ListgameParser.parse(@default_nick, @query)
    end

    def primary_query
      @primary_query ||= build_primary_query
    end

    alias :query :primary_query

    def compound_query?
      self.ast.compound_query?
    end

    def secondary_query
      @secondary_query ||= build_secondary_query
    end

    def query_list
      @query_list ||= build_query_list
    end

  private
    def build_primary_query
      AST::ASTQueryBuilder.build(self.default_nick, self.ast, self.ast.head.dup)
    end

    def build_secondary_query
      AST::ASTQueryBuilder.build(self.default_nick, self.ast,
                                 self.ast.full_tail.dup)
    end

    def build_query_list
      list = ::Sql::QueryList.new
      list << primary_query
      list << secondary_query if compound_query?
      list.filter = ast.filter
      list.sorts = ast.sorts
      list
    end
  end
end