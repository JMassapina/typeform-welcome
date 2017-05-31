FROM ruby:2.3-onbuild

EXPOSE 4567

ENTRYPOINT ["ruby", "welcome.rb", "-o", "0.0.0.0"]
