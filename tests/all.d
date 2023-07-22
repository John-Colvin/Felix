import unit_threaded.runner : runTestsMain;

mixin runTestsMain!(
    "ast",
    "interpreter",
    "lexer",
    "parser"
);