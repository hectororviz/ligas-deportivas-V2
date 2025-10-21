import { Module } from '@nestjs/common';
import { CaptchaService } from './captcha.service';
import { ConfigModule } from '@nestjs/config';

@Module({
  imports: [ConfigModule],
  providers: [CaptchaService],
  exports: [CaptchaService]
})
export class CaptchaModule {}
