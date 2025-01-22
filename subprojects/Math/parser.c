#include "parser.h"
#include <stdlib.h>

static OperatorType token_to_op(TokenType token) {
	switch (token) {
		case PLUS: return OP_ADD;

		case MINUS: return OP_SUBTRACT;

		case MULTIPLY: return OP_MULTIPLY;

		case DIVIDE: return OP_DIVIDE;

		// Should never happen
		default: return OP_ADD;
	}
}

static ParseResult create_result(ASTNode* node) {
	ParseResult result = { node, NULL };

	return result;
}

static ParseResult create_error(const char* message) {
	ParseResult result = { NULL, message };

	return result;
}

static ASTNode* create_number_node(double value) {
	ASTNode* node = malloc(sizeof(ASTNode));

	node->type = NODE_NUMBER;
	node->data.number = value;
	return node;
}

static ASTNode* create_binary_op_node(ASTNode* left, TokenType op, ASTNode* right) {
	ASTNode* node = malloc(sizeof(ASTNode));

	node->type = NODE_BINARY_OP;
	node->data.binary.left = left;
	node->data.binary.op = token_to_op(op);
	node->data.binary.right = right;
	return node;
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

void free_ast_node(ASTNode* node) {
	if (node) {
		switch (node->type) {
			case NODE_NUMBER:
				free(node);
				break;

			case NODE_BINARY_OP:
				free_ast_node(node->data.binary.left);
				free_ast_node(node->data.binary.right);
				free(node);
				break;
		}
	}
}

// Forward declarations for recursive descent
static ParseResult parse_expression(Parser* parser);
static ParseResult parse_term(Parser* parser);
static ParseResult parse_factor(Parser* parser);

static ParseResult parse_factor(Parser* parser) {
	Token token = parser->current_token;

	if (token.type == NUMBER) {
		advance_token(parser);
		return create_result(create_number_node(token.value));
	}

	if (token.type == LPAREN) {
		advance_token(parser);
		ParseResult result = parse_expression(parser);
		if (result.error) {
			return result;
		}

		if (parser->current_token.type != RPAREN) {
			free_ast_node(result.node);
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
			free_ast_node(left.node);
			return right;
		}

		if (op == DIVIDE && right.node->data.number == 0) {
			free_ast_node(left.node);
			free_ast_node(right.node);
			return create_error("Division by zero");
		}

		left.node = create_binary_op_node(left.node, op, right.node);
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
			free_ast_node(left.node);
			return right;
		}

		left.node = create_binary_op_node(left.node, op, right.node);
	}

	return left;
}

ParseResult parser_parse(Parser* parser) {
	ParseResult result = parse_expression(parser);

	if (result.error) {
		return result;
	}

	if (parser->current_token.type != EOF) {
		free_ast_node(result.node);
		return create_error("Unexpected token");
	}

	return result;
}
