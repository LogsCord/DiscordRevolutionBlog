function evaluate(node, ctx) {
    switch (node.type) {
        case "identifier":
            return ctx[node.name];

        case "string":
        case "number":
            return node.value;

        case "call":
            return evaluateCall(node, ctx);

        case "projection":
            return evaluateProjection(node, ctx);

        case "binary":
            return evaluateBinary(node, ctx);

        case "unary":
            return evaluateUnary(node, ctx);

        case "set":
            return node.values;
            
        default:
            throw new Error("Unknown AST node: " + node.type);
    }
}

function evaluateBinary(node, ctx) {
    const leftVal  = evaluate(node.left, ctx);
    const rightVal = evaluate(node.right, ctx);
debugger;
    switch (node.op) {
        case "in":
            // CAS 1 : left est une projection (roles(executor)[*])
            if (node.left.type === "projection") {
                return leftVal.some(v => rightVal.includes(v));
            }

            // CAS 2  left est une liste (roles(executor)) et on veut tester tous les éléments
            if (Array.isArray(leftVal)) {
                return leftVal.every(v => rightVal.includes(v));
            }
            
            // CAS 3 : left est une valeur simple
            return rightVal.includes(leftVal);

        case "not in":
            // CAS 1 : left est une projection (roles(executor)[*])
            if (node.left.type === "projection") {
                return leftVal.every(v => !rightVal.includes(v));
            }

            // CAS 2  left est une liste (roles(executor)) et on veut tester tous les éléments
            if (Array.isArray(leftVal)) {
                return leftVal.every(v => !rightVal.includes(v));
            }

            // CAS 3 : left est une valeur simple
            return !rightVal.includes(leftVal);

        case "==":  return leftVal == rightVal;
        case "!=":  return leftVal != rightVal;
        case ">":   return leftVal > rightVal;
        case "<":   return leftVal < rightVal;
        case ">=":  return leftVal >= rightVal;
        case "<=":  return leftVal <= rightVal;
        case "and": return leftVal && rightVal;
        case "or":  return leftVal || rightVal;
    }
}

function evaluateUnary(node, ctx) {
    const v = evaluate(node.value, ctx);
    if (node.op === "not") return !v;
}

function evaluateCall(node, ctx) {
    switch (node.name) {
        case "roles": return ctx.roles(node.args[0]);
        case "permissions": return ctx.permissions(node.args[0]);
        default:
            throw new Error("Unknown function " + node.name);
    }
}

function evaluateProjection(node, ctx) {
    const val = evaluate(node.source, ctx);
    switch (node.op) {
        case "*":
            if (!Array.isArray(val)) return [];
            return val.flat();
    }
}

// Return "true"

evaluate({
    type: "binary",
    op: "in",
    left: {
        type: "call",
        name: "roles",
        args: ["executor"],
    },
    right: { type: "set", values: [ "d", "c", "b" ] },
}, {
     executor: "ID",
     roles: () => [ "b", "c"],
});
