FROM ruby:2.3-onbuild

EXPOSE 4567

ENTRYPOINT ["ruby", "typeform_endpoints.rb", "-o", "0.0.0.0"]
