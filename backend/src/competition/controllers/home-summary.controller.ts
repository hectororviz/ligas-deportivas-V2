import { Controller, Get } from '@nestjs/common';
import { HomeSummaryService } from '../services/home-summary.service';

@Controller()
export class HomeSummaryController {
  constructor(private readonly homeSummaryService: HomeSummaryService) {}

  @Get('home/summary')
  summary() {
    return this.homeSummaryService.getSummary();
  }
}
