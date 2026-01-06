import { Controller, Get } from '@nestjs/common';
import { HomeSummaryDto } from '../dto/home-summary.dto';
import { HomeSummaryService } from '../services/home-summary.service';

@Controller()
export class HomeSummaryController {
  constructor(private readonly homeSummaryService: HomeSummaryService) {}

  @Get('home/summary')
  summary(): Promise<HomeSummaryDto> {
    return this.homeSummaryService.getSummary();
  }
}
