
ANTLRDIR=/usr/local
ANTLRLIB=$(ANTLRDIR)/antlr-4.5-complete.jar
ANTLR=$(ANTLRDIR)/bin/antlr4
GRUN=$(ANTLRDIR)/bin/grun
DLLSPATH=../pddlnet
CSANTLR=pddlListener.cs pddlBaseListener.cs pddlLexer.cs pddlParser.cs
LIBSTEST=-reference:NUnit.Framework,Microsoft.CSharp,pddlnet
MONOPATH=/Library/Frameworks/Mono.framework/Libraries/mono/4.5/
NUNITCONSOLE="/Library/Frameworks/Mono.framework/Versions/Current/bin/nunit-console4"
ANTLRNET=-reference:Antlr4.Runtime.dll
NUGET=nuget


export CLASSPATH:=.:$(ANTLRLIB)

all: testgrammar parsers

parsers: pyparser csparser

testgrammar: pddl.g4
	mkdir -p tmp && \
	$(ANTLR) -o tmp pddl.g4 && \
	cd tmp && javac *.java && \
	$(GRUN) pddl domain ../examples-pddl/domain-01.pddl && \
	$(GRUN) pddl problem ../examples-pddl/problem-01.pddl


pyparser: pddl.g4
	mkdir -p pddlpy && \
	$(ANTLR) -Dlanguage=Python3 -o pddlpy pddl.g4

pydist: pyparser pddlpy/pddl.py
	python3 setup.py bdist_wheel
	pip3 install -e .

pypitest: pydist
	python setup.py register -r pypitest && \
	python setup.py bdist_wheel upload -r pypitest

pypipublish: pydist
	python setup.py register -r pypi && \
	python setup.py bdist_wheel upload -r pypi

pydemo: pydist
	cd examples-python && \
	python3 demo.py 1 && \
	python3 demo.py 2 && \
	python3 demo.py 3

csparser: pddl.g4 pddlnet/pddl.cs
	mkdir -p pddlnet && \
	$(ANTLR) -Dlanguage=CSharp -package PDDLNET -o pddlnet pddl.g4 && \
	(cd pddlnet && \
	mcs -out:pddlnet.dll $(ANTLRNET) -t:library pddl.cs $(CSANTLR))

cstest: csparser pddlnet/pddltest.cs
	(cd pddlnet && \
	mcs -d:NUNIT $(LIBSTEST) -out:pddlnettest.dll $(ANTLRNET) -t:library pddltest.cs && \
	MONO_PATH=$(MONOPATH) $(NUNITCONSOLE) pddlnettest.dll --nologo )

csnuget: cstest
	(cd pddlnet && \
	rm -f pddlnet.dll.*.nupkg && \
	$(NUGET) pack pddlnet.dll.nuspec )

csnugetpublish: csnuget
	(cd pddlnet && \
	$(NUGET) push pddlnet.dll.*.nupkg )

