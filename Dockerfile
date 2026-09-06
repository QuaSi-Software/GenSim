FROM nrel/openstudio:3.10.0
WORKDIR /gensim
COPY ./Gemfile ./Gemfile.lock .
RUN bundle install --frozen
CMD ["ruby", "testrunner.rb"]