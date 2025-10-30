import { Body, Controller, Get, Post, Put, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RequestUser } from '../common/interfaces/request-user.interface';
import { MeService } from './me.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { RequestEmailChangeDto } from './dto/request-email-change.dto';
import { ConfirmEmailChangeDto } from './dto/confirm-email-change.dto';
import { ChangePasswordDto } from './dto/change-password.dto';

@Controller('me')
@UseGuards(JwtAuthGuard)
export class MeController {
  constructor(private readonly meService: MeService) {}

  @Get()
  getProfile(@CurrentUser() user: RequestUser) {
    return this.meService.getProfile(user.id);
  }

  @Put()
  updateProfile(@CurrentUser() user: RequestUser, @Body() dto: UpdateProfileDto) {
    return this.meService.updateProfile(user.id, dto);
  }

  @Post('email/request-change')
  requestEmailChange(@CurrentUser() user: RequestUser, @Body() dto: RequestEmailChangeDto) {
    return this.meService.requestEmailChange(user.id, dto);
  }

  @Post('email/confirm')
  confirmEmailChange(@CurrentUser() user: RequestUser, @Body() dto: ConfirmEmailChangeDto) {
    return this.meService.confirmEmailChange(user.id, dto);
  }

  @Post('password')
  changePassword(@CurrentUser() user: RequestUser, @Body() dto: ChangePasswordDto) {
    return this.meService.changePassword(user.id, dto);
  }

  @Post('avatar')
  @UseInterceptors(FileInterceptor('avatar'))
  uploadAvatar(@CurrentUser() user: RequestUser, @UploadedFile() file: Express.Multer.File) {
    return this.meService.updateAvatar(user.id, file);
  }
}
