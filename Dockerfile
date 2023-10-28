FROM grokloc/grokloc-perl5:0.0.2
WORKDIR /grokloc
ENV GROKLOC_ENV UNIT
COPY lib lib
COPY service service
COPY t t
COPY Makefile Makefile
CMD ["tail", "-f", "/dev/null"]
