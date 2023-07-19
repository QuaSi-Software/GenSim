FROM nrel/openstudio:3.0.0
WORKDIR /gensim
COPY ./Gemfile .
RUN bundle install
CMD ["ruby", "testrunner.rb"]