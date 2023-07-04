FROM public.ecr.aws/lambda/nodejs:14

LABEL maintainer="Enrique Plata"

COPY package.json ./

RUN npm install csv-parser

COPY app.js ./

CMD ["app.lambdaHandler"]
