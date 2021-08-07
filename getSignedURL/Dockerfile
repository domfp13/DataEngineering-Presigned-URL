LABEL "Createded by"="Luis Enrirque Fuentes Plata"

FROM public.ecr.aws/lambda/nodejs:14

COPY package.json ./

RUN npm install

COPY app.js ./

CMD ["app.lambdaHandler"]
