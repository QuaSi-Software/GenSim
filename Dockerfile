FROM nrel/openstudio:3.10.0
WORKDIR /gensim
COPY ./Gemfile .
RUN bundle install
RUN bundle update
CMD ["ruby", "testrunner.rb"]