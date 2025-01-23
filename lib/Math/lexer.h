#pragma once

typedef enum {
	NUMBER,
	PLUS,
	MINUS,
	MULTIPLY,
	DIVIDE,
	LPAREN,
	RPAREN,
	EOF,
	ERROR
} TokenType;

typedef struct {
	TokenType type;
	double value;
	const char* error_msg;
} Token;

typedef struct {
	const char* input;
	int position;
	int length;
} Lexer;

Lexer* lexer_create(const char* input);
void lexer_destroy(Lexer* lexer);
Token lexer_next_token(Lexer* lexer);
