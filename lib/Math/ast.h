#pragma once

typedef enum {
	NODE_NUMBER,
	NODE_BINARY_OP
} NodeType;

typedef enum {
	OP_ADD,
	OP_SUBTRACT,
	OP_MULTIPLY,
	OP_DIVIDE
} OperatorType;

typedef struct ASTNode {
	NodeType type;
	union {
		double number;
		struct {
			OperatorType op;
			struct ASTNode* left;
			struct ASTNode* right;
		} binary;
	} data;
} ASTNode;
