#pragma once
#include "lexer.h"
#include "ast.h"

typedef struct {
	Lexer* lexer;
	Token current_token;
} Parser;

typedef struct {
	ASTNode* node;
	const char* error;
} ParseResult;

Parser* parser_create(const char* input);
void parser_destroy(Parser* parser);
ParseResult parser_parse(Parser* parser);
void free_ast_node(ASTNode* node);
