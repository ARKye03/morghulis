#include "parser.h"
#include <stdlib.h>

static ParseResult create_result(double value) {
	ParseResult result = { value, NULL };

	return result;
}

static ParseResult create_error(const char* message) {
	ParseResult result = { 0.0, message };

	return result;
}

static void advance_token(Parser* parser) {
	parser->current_token = lexer_next_token(parser->lexer);
}

Parser* parser_create(const char* input) {
	Parser* parser = malloc(sizeof(Parser));

	parser->lexer = lexer_create(input);
	advance_token(parser);
	return parser;
}

void parser_destroy(Parser* parser) {
	lexer_destroy(parser->lexer);
	free(parser);
}

// Forward declarations for recursive descent
static ParseResult parse_expression(Parser* parser);
static ParseResult parse_term(Parser* parser);
static ParseResult parse_factor(Parser* parser);

static ParseResult parse_factor(Parser* parser) {
	Token token = parser->current_token;

	if (token.type == NUMBER) {
		advance_token(parser);
		return create_result(token.value);
	}

	if (token.type == LPAREN) {
		advance_token(parser);
		ParseResult result = parse_expression(parser);
		if (result.error) {
			return result;
		}

		if (parser->current_token.type != RPAREN) {
			return create_error("Expected ')'");
		}
		advance_token(parser);
		return result;
	}

	return create_error("Expected number or '('");
}

static ParseResult parse_term(Parser* parser) {
	ParseResult left = parse_factor(parser);

	if (left.error) {
		return left;
	}

	while (parser->current_token.type == MULTIPLY ||
		   parser->current_token.type == DIVIDE) {
		TokenType op = parser->current_token.type;
		advance_token(parser);

		ParseResult right = parse_factor(parser);
		if (right.error) {
			return right;
		}

		if (op == MULTIPLY) {
			left.value *= right.value;
		} else {
			if (right.value == 0) {
				return create_error("Division by zero");
			}
			left.value /= right.value;
		}
	}

	return left;
}

static ParseResult parse_expression(Parser* parser) {
	ParseResult left = parse_term(parser);

	if (left.error) {
		return left;
	}

	while (parser->current_token.type == PLUS ||
		   parser->current_token.type == MINUS) {
		TokenType op = parser->current_token.type;
		advance_token(parser);

		ParseResult right = parse_term(parser);
		if (right.error) {
			return right;
		}

		if (op == PLUS) {
			left.value += right.value;
		} else {
			left.value -= right.value;
		}
	}

	return left;
}

ParseResult parser_parse(Parser* parser) {
	ParseResult result = parse_expression(parser);

	if (result.error) {
		return result;
	}

	if (parser->current_token.type != EOF) {
		return create_error("Unexpected token");
	}

	return result;
}
