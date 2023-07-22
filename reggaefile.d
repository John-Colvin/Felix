import reggae;

alias test = executable!(
    ExeName("test"),
    Sources!(["src"]),
    Flags("-g -unittest -main -i"),
    ImportPaths(["../src", "src"])
);
mixin build!test;