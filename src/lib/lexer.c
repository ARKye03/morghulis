#include "lexer.h"
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

Lexer* lexer_create(const char* input) {
	Lexer* lexer = malloc(sizeof(Lexer));

	lexer->input = input;
	lexer->position = 0;
	lexer->length = strlen(input);
	return lexer;
}

void lexer_destroy(Lexer* lexer) {
	free(lexer);
}

static void skip_whitespace(Lexer* lexer) {
	while (lexer->position < lexer->length &&
		   isspace(lexer->input[lexer->position])) {
		lexer->position++;
	}
}

static Token create_token(TokenType type) {
	Token token = { type, 0.0, NULL };

	return token;
}

static Token create_number(double value) {
	Token token = { NUMBER, value, NULL };

	return token;
}

static Token create_error(const char* message) {
	Token token = { ERROR, 0.0, message };

	return token;
}

Token lexer_next_token(Lexer* lexer) {
	skip_whitespace(lexer);

	if (lexer->position >= lexer->length) {
		return create_token(EOF);
	}

	char c = lexer->input[lexer->position];
	lexer->position++;

	switch (c) {
		case '+': return create_token(PLUS);

		case '-': return create_token(MINUS);

		case '*': return create_token(MULTIPLY);

		case '/': return create_token(DIVIDE);

		case '(': return create_token(LPAREN);

		case ')': return create_token(RPAREN);

		default:
			if (isdigit(c) || c == '.') {
				lexer->position--;
				char* endptr;
				double value = strtod(lexer->input + lexer->position, &endptr);
				if (endptr == lexer->input + lexer->position) {
					return create_error("Invalid number");
				}
				lexer->position = endptr - lexer->input;
				return create_number(value);
			}
			return create_error("Invalid character");
	}
}
