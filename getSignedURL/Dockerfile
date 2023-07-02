FROM public.ecr.aws/lambda/nodejs:14

LABEL maintainer="Luis Enrique Fuentes Plata"

COPY package.json ./

RUN npm install csv-parser

COPY app.js ./

CMD ["app.lambdaHandler"]
