import reggae;

enum unitThreadedSourceDirs = [
        "unit-threaded/subpackages/assertions/source",
        "unit-threaded/subpackages/exception/source",
        "unit-threaded/subpackages/from/source",
        "unit-threaded/subpackages/runner/source",
];

alias unit_threaded = staticLibrary!(
    "unit-threaded.a",
    Sources!(unitThreadedSourceDirs),
    Flags(),
    ImportPaths(unitThreadedSourceDirs)
);

alias testObjs = objectFiles!(
    Sources!(["src", "SDC/src/source"], Files(["tests/all.d"])),
    Flags("-g -unittest"),
    ImportPaths(["src", "SDC/src"] ~ unitThreadedSourceDirs)
);

alias test = link!(
    ExeName("test"),
    () => testObjs ~ unit_threaded
);

mixin build!(test, unit_threaded);
